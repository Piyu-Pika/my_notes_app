import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

// w
class EditNoteScreen extends StatefulWidget {
  final Map<String, dynamic> note;
  final String noteId;

  EditNoteScreen({required this.note, required this.noteId});

  @override
  _EditNoteScreenState createState() => _EditNoteScreenState();
}

class _EditNoteScreenState extends State<EditNoteScreen> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late TextEditingController _linkController;
  late TextEditingController _tagController;
  bool _isLoading = false;
  late Color _selectedColor;
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
    _titleController = TextEditingController(text: widget.note['title']);
    _contentController = TextEditingController(text: widget.note['content']);
    _linkController = TextEditingController();
    _tagController = TextEditingController();
    _selectedColor = Color(widget.note['color'] ?? Colors.white.value);
    _tags = List<String>.from(widget.note['tags'] ?? []);
    _links = List<String>.from(widget.note['links'] ?? []);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _linkController.dispose();
    _tagController.dispose();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    Color textColor =
        _selectedColor.computeLuminance() > 0.5 ? Colors.black : Colors.white;

    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Note'),
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: _isLoading ? null : () => _saveNote(context),
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
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
                  ],
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
            TextField(
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
            ),
            SizedBox(height: 8),
            Text(
              'Edited: ${DateFormat.yMd().add_jm().format(DateTime.now())}',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall!
                  .copyWith(color: textColor),
            ),
            Divider(height: 20, color: textColor),
            TextField(
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
                    color: _selectedColor == color ? Colors.black : Colors.grey,
                    width: 2,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  void _saveNote(BuildContext context) async {
    if (_titleController.text.trim().isEmpty ||
        _contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Title and Content cannot be empty')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final user = FirebaseAuth.instance.currentUser!;
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('notes')
          .doc(widget.noteId)
          .update({
        'title': _titleController.text.trim(),
        'content': _contentController.text.trim(),
        'links': _links,
        'timestamp': FieldValue.serverTimestamp(),
        'color': _selectedColor.value,
        'tags': _tags,
      });

      Navigator.pop(context, {
        'title': _titleController.text.trim(),
        'content': _contentController.text.trim(),
        'links': _links,
        'timestamp': Timestamp.now(),
        'color': _selectedColor.value,
        'tags': _tags,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Note updated successfully')),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update note: $error')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
