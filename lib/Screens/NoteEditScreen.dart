import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note['title']);
    _contentController = TextEditingController(text: widget.note['content']);
    _linkController = TextEditingController(text: widget.note['link']);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _linkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                  children: [
                    Card(
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: TextField(
                          controller: _titleController,
                          decoration: InputDecoration(
                            labelText: 'Title',
                            border: InputBorder.none,
                          ),
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
                        padding: const EdgeInsets.all(8.0),
                        child: TextField(
                          controller: _contentController,
                          decoration: InputDecoration(
                            labelText: 'Content',
                            border: InputBorder.none,
                          ),
                          maxLines: null,
                          keyboardType: TextInputType.multiline,
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    Card(
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: TextField(
                          controller: _linkController,
                          decoration: InputDecoration(
                            labelText: 'Link',
                            border: InputBorder.none,
                            prefixIcon: Icon(Icons.link),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
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
        'link': _linkController.text.trim(),
        'timestamp': FieldValue.serverTimestamp(),
      });

      Navigator.pop(context, {
        'title': _titleController.text.trim(),
        'content': _contentController.text.trim(),
        'link': _linkController.text.trim(),
        'timestamp': Timestamp.now(),
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