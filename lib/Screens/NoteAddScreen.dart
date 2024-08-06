import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class AddNoteScreen extends StatefulWidget {
  @override
  _AddNoteScreenState createState() => _AddNoteScreenState();
}

class _AddNoteScreenState extends State<AddNoteScreen>
    with WidgetsBindingObserver {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _linkController = TextEditingController();
  final _tagController = TextEditingController();
  bool _isLoading = false;
  final gemini = Gemini.instance;
  Color _selectedColor = Colors.white;
  List<String> _tags = [];
  List<String> _links = [];

  final List<Color> _colorOptions = [
    Colors.white,
    Colors.red[100]!,
    Colors.blue[100]!,
    Colors.green[100]!,
    Colors.yellow[100]!,
    Colors.purple[100]!,
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadSavedData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _titleController.dispose();
    _contentController.dispose();
    _linkController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _saveDataLocally();
    }
  }

  Future<void> _loadSavedData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _titleController.text = prefs.getString('temp_title') ?? '';
      _contentController.text = prefs.getString('temp_content') ?? '';
      _selectedColor = Color(prefs.getInt('temp_color') ?? Colors.white.value);
      _tags = prefs.getStringList('temp_tags') ?? [];
      _links = prefs.getStringList('temp_links') ?? [];
    });
  }

  Future<void> _saveDataLocally() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('temp_title', _titleController.text);
    await prefs.setString('temp_content', _contentController.text);
    await prefs.setInt('temp_color', _selectedColor.value);
    await prefs.setStringList('temp_tags', _tags);
    await prefs.setStringList('temp_links', _links);
  }

  Future<void> _clearLocalData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('temp_title');
    await prefs.remove('temp_content');
    await prefs.remove('temp_color');
    await prefs.remove('temp_tags');
    await prefs.remove('temp_links');
  }

  Future<void> _generateTitle() async {
    if (_contentController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter some content first')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      String prompt = '''
      Based on the following note content, generate a concise and relevant title:
      ${_contentController.text}
      
      The title should be short, catchy, and representative of the main idea in the content.
      under 50 characters
      ''';

      final response = await gemini.text(prompt);
      String generatedTitle =
          response?.content?.parts?.last.text ?? 'Generated Title';

      generatedTitle = generatedTitle.trim();
      if (generatedTitle.length > 50) {
        generatedTitle = generatedTitle.substring(0, 47) + '...';
      }

      setState(() {
        _titleController.text = generatedTitle;
      });
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to generate title: $error')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _addTag() {
    String tag = _tagController.text.trim();
    if (tag.isNotEmpty) {
      if (!tag.startsWith('#')) {
        tag = '#$tag';
      }
      setState(() {
        if (!_tags.contains(tag)) {
          _tags.add(tag);
        }
        _tagController.clear();
      });
    }
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
  }

  void _addLink() {
    String link = _linkController.text.trim();
    if (link.isNotEmpty) {
      setState(() {
        if (!_links.contains(link)) {
          _links.add(link);
        }
        _linkController.clear();
      });
    }
  }

  void _removeLink(String link) {
    setState(() {
      _links.remove(link);
    });
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final user = FirebaseAuth.instance.currentUser!;
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('notes')
            .add({
          'title': _titleController.text.trim(),
          'content': _contentController.text.trim(),
          'links': _links,
          'timestamp': FieldValue.serverTimestamp(),
          'color': _selectedColor.value,
          'tags': _tags,
        });

        await _clearLocalData();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Note added successfully')),
        );
      } catch (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add note: $error')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<bool> _onWillPop() async {
    if (_titleController.text.isNotEmpty ||
        _contentController.text.isNotEmpty ||
        _tags.isNotEmpty ||
        _links.isNotEmpty) {
      return await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('Discard changes?'),
              content:
                  Text('If you go back, your unsaved changes will be lost.'),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text('Cancel'),
                ),
                TextButton(
                  onPressed: () async {
                    await _clearLocalData();
                    Navigator.of(context).pop(true);
                  },
                  child: Text('Discard'),
                ),
              ],
            ),
          ) ??
          false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    Color textColor =
        _selectedColor.computeLuminance() > 0.5 ? Colors.black : Colors.white;

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Add Note'),
          actions: [
            IconButton(
              icon: Icon(Icons.save),
              onPressed: _isLoading ? null : _submitForm,
            ),
          ],
        ),
        body: _isLoading
            ? Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildNoteCard(textColor),
                        SizedBox(height: 20),
                        _buildLinksSection(),
                        SizedBox(height: 20),
                        _buildTagsSection(),
                        SizedBox(height: 20),
                        _buildColorSelection(),
                        SizedBox(height: 20),
                        Center(
                          child: ElevatedButton.icon(
                            icon: Icon(Icons.save),
                            label: Text('Save Note'),
                            onPressed: _isLoading ? null : _submitForm,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).primaryColor,
                              padding: EdgeInsets.symmetric(
                                  horizontal: 40, vertical: 15),
                              textStyle: TextStyle(fontSize: 18),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildNoteCard(Color textColor) {
    return Card(
      elevation: 4,
      color: _selectedColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _titleController,
                    style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Title',
                      hintStyle: TextStyle(color: textColor.withOpacity(0.6)),
                    ),
                    validator: (value) =>
                        value!.isEmpty ? 'Please enter a title' : null,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.auto_awesome, color: textColor),
                  onPressed: _generateTitle,
                  tooltip: 'Generate title',
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              'Created: ${DateFormat.yMd().add_jm().format(DateTime.now())}',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall!
                  .copyWith(color: textColor),
            ),
            Divider(height: 20, color: textColor),
            TextFormField(
              controller: _contentController,
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge!
                  .copyWith(color: textColor),
              maxLines: null,
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: 'Content',
                hintStyle: TextStyle(color: textColor.withOpacity(0.6)),
              ),
              validator: (value) =>
                  value!.isEmpty ? 'Please enter some content' : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLinksSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Links:',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        SizedBox(height: 8),
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _linkController,
                        decoration: InputDecoration(
                          hintText: 'Add a link',
                          border: InputBorder.none,
                          prefixIcon: Icon(Icons.link),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.add),
                      onPressed: _addLink,
                    ),
                  ],
                ),
                SizedBox(height: 8),
                ..._links.map((link) => ListTile(
                      leading: Icon(Icons.link),
                      title: Text(link),
                      trailing: IconButton(
                        icon: Icon(Icons.delete),
                        onPressed: () => _removeLink(link),
                      ),
                    )),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTagsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tags:',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        SizedBox(height: 8),
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _tagController,
                        decoration: InputDecoration(
                          hintText: 'Add a tag',
                          border: InputBorder.none,
                          prefixIcon: Icon(Icons.tag),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.add),
                      onPressed: _addTag,
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: _tags
                      .map((tag) => Chip(
                            label: Text(tag),
                            onDeleted: () => _removeTag(tag),
                            backgroundColor:
                                Theme.of(context).primaryColor.withOpacity(0.1),
                          ))
                      .toList(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildColorSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Note Color:',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        SizedBox(height: 8),
        Wrap(
          spacing: 12,
          children: _colorOptions.map((Color color) {
            return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedColor = color;
                  });
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color:
                          _selectedColor == color ? Colors.black : Colors.grey,
                      width: 2,
                    ),
                  ),
                ));
          }).toList(),
        ),
      ],
    );
  }
}
