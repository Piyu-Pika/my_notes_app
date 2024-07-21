import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:my_notes_app/Screens/NoteAddScreen.dart';
import 'package:my_notes_app/Screens/NotesDetailsScreen.dart';

class NotesScreen extends StatefulWidget {
  final Function toggleTheme;
  final bool isDarkMode;

  NotesScreen({required this.toggleTheme, required this.isDarkMode});

  @override
  _NotesScreenState createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  String _searchQuery = '';
  bool _isSearching = false;

  void _showLogoutConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Logout'),
          content: Text('Are you sure you want to log out?'),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Logout'),
              onPressed: () {
                Navigator.of(context).pop();
                FirebaseAuth.instance.signOut();
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
    final user = FirebaseAuth.instance.currentUser!;
    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Search notes...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(
                      color:
                          widget.isDarkMode ? Colors.white70 : Colors.black54),
                ),
                style: TextStyle(
                    color: widget.isDarkMode ? Colors.white : Colors.black),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.toLowerCase();
                  });
                },
              )
            : Text('My Notes'),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchQuery = '';
                }
              });
            },
          ),
          IconButton(
            icon: Icon(widget.isDarkMode ? Icons.light_mode : Icons.dark_mode),
            onPressed: () {
              widget.toggleTheme();
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _showLogoutConfirmationDialog,
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('notes')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Something went wrong'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No notes yet. Add your first note!'));
          }

          var filteredDocs = snapshot.data!.docs.where((doc) {
            Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
            return data['title']
                    .toString()
                    .toLowerCase()
                    .contains(_searchQuery) ||
                data['content'].toString().toLowerCase().contains(_searchQuery);
          }).toList();

          if (filteredDocs.isEmpty) {
            return Center(child: Text('No matching notes found'));
          }

          return ListView.builder(
            itemCount: filteredDocs.length,
            itemBuilder: (context, index) {
              Map<String, dynamic> data =
                  filteredDocs[index].data() as Map<String, dynamic>;
              Color noteColor = Color(data['color'] ?? Colors.white.value);
              Color textColor = getTextColor(noteColor);
              return Card(
                elevation: 2,
                margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                color: noteColor,
                child: ListTile(
                  title: Text(
                    data['title'] ?? 'No Title',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  subtitle: Text(
                    data['content'] ?? 'No Content',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: textColor),
                  ),
                  leading: CircleAvatar(
                    backgroundColor: textColor,
                    child: Text(
                      (data['title'] ?? 'N')[0].toUpperCase(),
                      style: TextStyle(
                        color: noteColor,
                      ),
                    ),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => NoteDetailScreen(
                          note: data,
                          noteId: filteredDocs[index].id,
                        ),
                      ),
                    ).then((updatedNote) {
                      if (updatedNote != null) {
                        // If the note was updated, you can handle it here if needed
                      }
                    });
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddNoteScreen()),
          );
        },
      ),
    );
  }
}
