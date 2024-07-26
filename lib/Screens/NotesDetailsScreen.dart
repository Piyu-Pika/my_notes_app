import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:my_notes_app/Screens/ChatWithNotes.dart';
import 'package:my_notes_app/Screens/NoteEditScreen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';

// w
class NoteDetailScreen extends StatefulWidget {
  final Map<String, dynamic> note;
  final String noteId;

  NoteDetailScreen({required this.note, required this.noteId});

  @override
  _NoteDetailScreenState createState() => _NoteDetailScreenState();
}

class _NoteDetailScreenState extends State<NoteDetailScreen> {
  late Map<String, dynamic> _note;

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

  void _shareNote() {
    String links = (_note['links'] as List<dynamic>?)?.join('\n') ?? '';
    Share.share('${_note['title']}\n\n${_note['content']}\n\nLinks:\n$links');
  }

  void _changeColor() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Pick a color'),
          content: SingleChildScrollView(
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _colorOptions.map((Color color) {
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _note['color'] = color.value;
                    });
                    Navigator.of(context).pop();
                    _updateNoteColor();
                  },
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey),
                    ),
                    child: color.value == _note['color']
                        ? Icon(Icons.check, color: Colors.black)
                        : null,
                  ),
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  void _updateNoteColor() {
    final user = FirebaseAuth.instance.currentUser!;
    FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('notes')
        .doc(widget.noteId)
        .update({'color': _note['color']});
  }

  @override
  Widget build(BuildContext context) {
    Color noteColor = Color(_note['color'] ?? Colors.white.value);
    Color textColor =
        noteColor.computeLuminance() > 0.5 ? Colors.black : Colors.white;

    return Scaffold(
      appBar: AppBar(
        title: Text(_note['title'] ?? 'Note Details'),
        actions: [
          IconButton(icon: Icon(Icons.share), onPressed: _shareNote),
          IconButton(icon: Icon(Icons.color_lens), onPressed: _changeColor),
          IconButton(
              icon: Icon(Icons.delete), onPressed: () => _deleteNote(context)),
        ],
      ),
      body: GestureDetector(
        onDoubleTap: () => _editNote(context),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildNoteCard(noteColor, textColor),
                SizedBox(height: 20),
                _buildLinksSection(),
                SizedBox(height: 20),
                _buildTagsSection(),
              ],
            ),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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

  Widget _buildLinksSection() {
    List<String> links = List<String>.from(_note['links'] ?? []);
    if (links.isEmpty) return SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Links:',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        SizedBox(height: 8),
        Column(
          children: links
              .map((link) => Card(
                    elevation: 2,
                    child: ListTile(
                      leading: Icon(Icons.link),
                      title: Text(link),
                      onTap: () => _launchUrl(link),
                    ),
                  ))
              .toList(),
        ),
      ],
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
