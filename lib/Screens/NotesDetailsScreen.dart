import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:my_notes_app/Screens/ChatWithNotes.dart';
import 'package:my_notes_app/Screens/NoteEditScreen.dart';
import 'package:url_launcher/url_launcher.dart';

class NoteDetailScreen extends StatefulWidget {
  final Map<String, dynamic> note;
  final String noteId;

  NoteDetailScreen({required this.note, required this.noteId});

  @override
  _NoteDetailScreenState createState() => _NoteDetailScreenState();
}

class _NoteDetailScreenState extends State<NoteDetailScreen> {
  Future<void> _launchUrl(String url) async {
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'https://' + url;
    }

    final Uri uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      } else {
        throw 'Could not launch $url';
      }
    } catch (e) {
      print('Error launching URL: $e');
      _showErrorDialog('Could not launch $url\nError: $e');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Error'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Color getTextColor(Color backgroundColor) {
    if (backgroundColor.computeLuminance() > 0.5) {
      return Colors.black;
    } else {
      return Colors.white;
    }
  }

  @override
  Widget build(BuildContext context) {
    Color noteColor = Color(widget.note['color'] ?? Colors.white.value);
    Color textColor = getTextColor(noteColor);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.note['title'] ?? 'Note Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _editNote(context),
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _deleteNote(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                elevation: 4,
                color: noteColor,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.note['title'] ?? 'No Title',
                        style:
                            Theme.of(context).textTheme.headlineSmall!.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Created: ${widget.note['timestamp'] != null ? DateFormat.yMd().add_jm().format(widget.note['timestamp'].toDate()) : 'No Date'}',
                        style: Theme.of(context).textTheme.bodySmall!.copyWith(
                              color: textColor,
                            ),
                      ),
                      Divider(height: 20, color: textColor),
                      SelectableText(
                        widget.note['content'] ?? 'No content',
                        style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                              color: textColor,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20),
              if (widget.note['link'] != null && widget.note['link'].isNotEmpty)
                Card(
                  elevation: 4,
                  child: ListTile(
                    leading: Icon(Icons.link),
                    title: Text('Attached Link'),
                    subtitle: Text(widget.note['link']),
                    onTap: () {
                      _launchUrl(widget.note['link']);
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToChatScreen(context),
        child: Icon(Icons.chat),
        tooltip: 'Chat with this note',
      ),
    );
  }

  void _navigateToChatScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NoteChatScreen(
          noteContent: widget.note['content'],
          noteTitle: widget.note['title'],
        ),
      ),
    );
  }

  void _editNote(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            EditNoteScreen(note: widget.note, noteId: widget.noteId),
      ),
    ).then((updatedNote) {
      if (updatedNote != null) {
        setState(() {
          widget.note['title'] = updatedNote['title'];
          widget.note['content'] = updatedNote['content'];
          widget.note['link'] = updatedNote['link'];
          widget.note['timestamp'] = updatedNote['timestamp'];
          widget.note['color'] = updatedNote['color'];
        });
      }
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Note deleted successfully')),
      );
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete note: $error')),
      );
    });
  }
}
