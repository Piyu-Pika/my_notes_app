import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class NoteDetailScreen extends StatelessWidget {
  final Map<String, dynamic> note;
  final String noteId;

  NoteDetailScreen({required this.note, required this.noteId});

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      // Handle the case when the URL can't be launched
      var context;
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
        title: Text(note['title'] ?? 'Note Details'),
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
            Text(note['content'] ?? 'No content',
                style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 20),
            if (note['link'] != null && note['link'].isNotEmpty)
              GestureDetector(
                child: Text('Link: ${note['link']}',
                    style: const TextStyle(color: Colors.blue)),
                onTap: () {
                  _launchUrl(note['link']);
                },
              ),
            const SizedBox(height: 20),
            Text(
              'Created: ${note['timestamp'] != null ? DateFormat.yMd().add_jm().format(note['timestamp'].toDate()) : 'No Date'}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
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
        .doc(noteId)
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
