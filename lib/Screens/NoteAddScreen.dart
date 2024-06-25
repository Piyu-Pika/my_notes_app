import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddNoteScreen extends StatefulWidget {
  @override
  _AddNoteScreenState createState() => _AddNoteScreenState();
}

class _AddNoteScreenState extends State<AddNoteScreen> {
  final _formKey = GlobalKey<FormState>();
  String _title = '';
  String _content = '';
  String _link = '';

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final user = FirebaseAuth.instance.currentUser!;
      FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('notes')
          .add({
        'title': _title,
        'content': _content,
        'link': _link,
        'timestamp': FieldValue.serverTimestamp(),
      }).then((_) {
        Navigator.pop(context);
      }).catchError((error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add note: $error')),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Note')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            TextFormField(
              decoration: const InputDecoration(labelText: 'Title'),
              validator: (value) =>
                  value!.isEmpty ? 'Please enter a title' : null,
              onSaved: (value) => _title = value!,
            ),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Content'),
              maxLines: 9,
              validator: (value) =>
                  value!.isEmpty ? 'Please enter some content' : null,
              onSaved: (value) => _content = value!,
            ),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Link (optional)'),
              onSaved: (value) => _link = value ?? '',
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _submitForm,
              child: const Text('Save Note'),
            ),
          ],
        ),
      ),
    );
  }
}
