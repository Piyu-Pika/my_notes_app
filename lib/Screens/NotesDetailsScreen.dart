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
  late Map<String, dynamic> _note;

  @override
  void initState() {
    super.initState();
    _note = Map<String, dynamic>.from(widget.note);
  }

  Future<void> _launchUrl(String url) async {
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'https://' + url;
    }

    final Uri uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
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
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  Color getTextColor(Color backgroundColor) {
    return backgroundColor.computeLuminance() > 0.5
        ? Colors.black
        : Colors.white;
  }

  @override
  Widget build(BuildContext context) {
    Color noteColor = Color(_note['color'] ?? Colors.white.value);
    Color textColor = getTextColor(noteColor);

    return Scaffold(
      appBar: AppBar(
        title: Text(_note['title'] ?? 'Note Details'),
        actions: [
          IconButton(
              icon: Icon(Icons.edit), onPressed: () => _editNote(context)),
          IconButton(
              icon: Icon(Icons.delete), onPressed: () => _deleteNote(context)),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildNoteCard(noteColor, textColor),
              SizedBox(height: 20),
              _buildLinkCard(),
              SizedBox(height: 20),
              _buildTagsSection(),
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

  Widget _buildNoteCard(Color noteColor, Color textColor) {
    return Card(
      elevation: 4,
      color: noteColor,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _note['title'] ?? 'No Title',
              style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
            ),
            SizedBox(height: 8),
            Text(
              'Created: ${_note['timestamp'] != null ? DateFormat.yMd().add_jm().format(_note['timestamp'].toDate()) : 'No Date'}',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall!
                  .copyWith(color: textColor),
            ),
            Divider(height: 20, color: textColor),
            SelectableText(
              _note['content'] ?? 'No content',
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge!
                  .copyWith(color: textColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLinkCard() {
    if (_note['link'] == null || _note['link'].isEmpty)
      return SizedBox.shrink();

    return Card(
      elevation: 4,
      child: ListTile(
        leading: Icon(Icons.link),
        title: Text('Attached Link'),
        subtitle: Text(_note['link']),
        onTap: () => _launchUrl(_note['link']),
      ),
    );
  }

  Widget _buildTagsSection() {
    List<String> tags = List<String>.from(_note['tags'] ?? []);
    if (tags.isEmpty) return SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tags:',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: tags
              .map((tag) => Chip(
                    label: Text(tag),
                    backgroundColor:
                        Theme.of(context).primaryColor.withOpacity(0.1),
                  ))
              .toList(),
        ),
      ],
    );
  }

  void _navigateToChatScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NoteChatScreen(
          noteContent: _note['content'],
          noteTitle: _note['title'],
        ),
      ),
    );
  }

  void _editNote(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            EditNoteScreen(note: _note, noteId: widget.noteId),
      ),
    ).then((updatedNote) {
      if (updatedNote != null) {
        setState(() {
          _note = updatedNote;
        });
      }
    });
  }

  void _deleteNote(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Delete Note"),
          content: Text("Are you sure you want to delete this note?"),
          actions: <Widget>[
            TextButton(
              child: Text("Cancel"),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text("Delete", style: TextStyle(color: Colors.red)),
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
