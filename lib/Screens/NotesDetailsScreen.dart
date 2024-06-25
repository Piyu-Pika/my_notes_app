import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class NoteDetailScreen extends StatefulWidget {
  final Map<String, dynamic> note;
  final String noteId;

  NoteDetailScreen({required this.note, required this.noteId});

  @override
  _NoteDetailScreenState createState() => _NoteDetailScreenState();
}

class _NoteDetailScreenState extends State<NoteDetailScreen> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late TextEditingController _linkController;

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

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Could not launch URL'),
            content: Text('Could not launch $url'),
            actions: <Widget>[
              TextButton(
                child: const Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.note['title'] ?? 'Note Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _deleteNote(context),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.note['content'] ?? 'No content',
                style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 20),
            if (widget.note['link'] != null && widget.note['link'].isNotEmpty)
              GestureDetector(
                child: Text('Link: ${widget.note['link']}',
                    style: const TextStyle(color: Colors.blue)),
                onTap: () {
                  _launchUrl(widget.note['link']);
                },
              ),
            const SizedBox(height: 20),
            Text(
              'Created: ${widget.note['timestamp'] != null ? DateFormat.yMd().add_jm().format(widget.note['timestamp'].toDate()) : 'No Date'}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _editNote(context),
        child: const Icon(Icons.edit),
      ),
    );
  }

  void _editNote(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Edit Note"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(labelText: 'Title'),
                ),
                TextField(
                  controller: _contentController,
                  decoration: const InputDecoration(labelText: 'Content'),
                  maxLines: 5,
                ),
                TextField(
                  controller: _linkController,
                  decoration: const InputDecoration(labelText: 'Link'),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text("Cancel"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text("Save"),
              onPressed: () {
                _performEdit(context);
              },
            ),
          ],
        );
      },
    );
  }

  void _performEdit(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;
    FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('notes')
        .doc(widget.noteId)
        .update({
      'title': _titleController.text,
      'content': _contentController.text,
      'link': _linkController.text,
      'timestamp': FieldValue.serverTimestamp(),
    }).then((_) {
      Navigator.of(context).pop(); // Close the dialog
      setState(() {
        widget.note['title'] = _titleController.text;
        widget.note['content'] = _contentController.text;
        widget.note['link'] = _linkController.text;
        widget.note['timestamp'] = Timestamp.now();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Note updated successfully')),
      );
    }).catchError((error) {
      Navigator.of(context).pop(); // Close the dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update note: $error')),
      );
    });
  }

  void _deleteNote(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Delete Note"),
          content: const Text("Are you sure you want to delete this note?"),
          actions: <Widget>[
            TextButton(
              child: const Text("Cancel"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text("Delete"),
              onPressed: () {
                Navigator.of(context).pop();
                _performDelete(context);
              },
            ),
          ],
        );
      },
    );
  }

  void _performDelete(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;
    FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('notes')
        .doc(widget.noteId)
        .delete()
        .then((_) {
      Navigator.pop(context);
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete note: $error')),
      );
    });
  }
}
