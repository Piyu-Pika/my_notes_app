import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:shared_preferences/shared_preferences.dart';

// w
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
      _linkController.text = prefs.getString('temp_link') ?? '';
      _selectedColor = Color(prefs.getInt('temp_color') ?? Colors.white.value);
      _tags = prefs.getStringList('temp_tags') ?? [];
    });
  }

  Future<void> _saveDataLocally() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('temp_title', _titleController.text);
    await prefs.setString('temp_content', _contentController.text);
    await prefs.setString('temp_link', _linkController.text);
    await prefs.setInt('temp_color', _selectedColor.value);
    await prefs.setStringList('temp_tags', _tags);
  }

  Future<void> _clearLocalData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('temp_title');
    await prefs.remove('temp_content');
    await prefs.remove('temp_link');
    await prefs.remove('temp_color');
    await prefs.remove('temp_tags');
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
        _linkController.text.isNotEmpty ||
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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

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
                        children: [
                          Card(
                            elevation: 4,
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8.0),
                              child: TextFormField(
                                controller: _titleController,
                                decoration: InputDecoration(
                                  labelText: 'Title',
                                  border: InputBorder.none,
                                  suffixIcon: IconButton(
                                    icon: Icon(Icons.auto_awesome_rounded),
                                    onPressed: _generateTitle,
                                    tooltip: 'Generate title',
                                  ),
                                ),
                                validator: (value) => value!.isEmpty
                                    ? 'Please enter a title'
                                    : null,
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 16),
                          Card(
                            elevation: 4,
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8.0),
                              child: TextFormField(
                                controller: _contentController,
                                decoration: InputDecoration(
                                  labelText: 'Content',
                                  border: InputBorder.none,
                                ),
                                validator: (value) => value!.isEmpty
                                    ? 'Please enter some content'
                                    : null,
                                maxLines: 9,
                                keyboardType: TextInputType.multiline,
                              ),
                            ),
                          ),
                          SizedBox(height: 16),
                          Card(
                            elevation: 4,
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8.0),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextFormField(
                                          controller: _linkController,
                                          decoration: InputDecoration(
                                            labelText: 'Add Link',
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
                                  Wrap(
                                    spacing: 8,
                                    children: _links
                                        .map((link) => Chip(
                                              label: Text(link,
                                                  style:
                                                      TextStyle(fontSize: 12)),
                                              onDeleted: () =>
                                                  _removeLink(link),
                                              backgroundColor: Theme.of(context)
                                                  .primaryColor
                                                  .withOpacity(0.1),
                                            ))
                                        .toList(),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: 16),
                          Card(
                            elevation: 4,
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Note Color',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
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
                                              color: _selectedColor == color
                                                  ? Colors.black
                                                  : Colors.grey,
                                              width: 2,
                                            ),
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: 16),
                          Card(
                            elevation: 4,
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8.0),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _tagController,
                                      decoration: InputDecoration(
                                        labelText: 'Add Tag',
                                        hintText: 'Enter tag (e.g., #work)',
                                        border: InputBorder.none,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.add),
                                    onPressed: _addTag,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children: _tags
                                .map((tag) => Chip(
                                      label: Text(tag),
                                      onDeleted: () => _removeTag(tag),
                                      backgroundColor: Theme.of(context)
                                          .primaryColor
                                          .withOpacity(0.1),
                                    ))
                                .toList(),
                          ),
                          SizedBox(height: 20),
                          ElevatedButton.icon(
                            icon: Icon(
                              Icons.save,
                              color: isDarkMode ? Colors.white : Colors.black87,
                            ),
                            label: Text(
                              'Save Note',
                              style: TextStyle(
                                color:
                                    isDarkMode ? Colors.white : Colors.black87,
                              ),
                            ),
                            onPressed: _isLoading ? null : _submitForm,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).primaryColor,
                              padding: EdgeInsets.symmetric(
                                  horizontal: 40, vertical: 15),
                              textStyle: TextStyle(
                                fontSize: 18,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
        ));
  }
}
