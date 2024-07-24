import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:my_notes_app/Screens/NoteAddScreen.dart';
import 'package:my_notes_app/Screens/NotesDetailsScreen.dart';

class NotesScreen extends StatefulWidget {
  final Function toggleTheme;
  bool isDarkMode;

  NotesScreen({required this.toggleTheme, required this.isDarkMode});

  @override
  _NotesScreenState createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  String _searchQuery = '';
  bool _isSearching = false;
  Set<String> _selectedTags = Set<String>();
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
              onPressed: () => Navigator.of(context).pop(),
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
    return backgroundColor.computeLuminance() > 0.5
        ? Colors.black
        : Colors.white;
  }

  void _toggleTag(String tag) {
    setState(() {
      if (_selectedTags.contains(tag)) {
        _selectedTags.remove(tag);
      } else {
        _selectedTags.add(tag);
      }
    });
  }

  Widget _buildTagFilter(List<String> allTags) {
    return Container(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: allTags.length,
        itemBuilder: (context, index) {
          final tag = allTags[index];
          final isSelected = _selectedTags.contains(tag);
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: FilterChip(
              label: Text(tag),
              selected: isSelected,
              onSelected: (_) => _toggleTag(tag),
            ),
          );
        },
      ),
    );
  }

  Future<void> _togglePinNote(String noteId, bool currentPinned) async {
    final user = FirebaseAuth.instance.currentUser!;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('notes')
        .doc(noteId)
        .update({'pinned': !currentPinned});
  }

  void _showPinOptions(
      BuildContext context, String noteId, bool currentPinned) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext bc) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: Icon(
                    currentPinned ? Icons.push_pin : Icons.push_pin_outlined),
                title: Text(currentPinned ? 'Unpin' : 'Pin'),
                onTap: () {
                  _togglePinNote(noteId, currentPinned);
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _deleteNote(BuildContext context, String noteId) {
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
                _performDelete(context, noteId);
              },
            ),
          ],
        );
      },
    );
  }

  void _performDelete(BuildContext context, String noteId) {
    final user = FirebaseAuth.instance.currentUser!;
    FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('notes')
        .doc(noteId)
        .delete()
        .then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Note deleted successfully')),
      );
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete note: $error')),
      );
    });
  }

  void _showOptionsDialog(BuildContext context, String noteId, bool isPinned) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Note Options"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading:
                    Icon(isPinned ? Icons.push_pin : Icons.push_pin_outlined),
                title: Text(isPinned ? "Unpin Note" : "Pin Note"),
                onTap: () {
                  Navigator.of(context).pop();
                  _togglePinNote(noteId, isPinned);
                },
              ),
              ListTile(
                leading: Icon(Icons.delete),
                title: Text("Delete Note"),
                onTap: () {
                  Navigator.of(context).pop();
                  _deleteNote(context, noteId);
                },
              ),
            ],
          ),
        );
      },
    );
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
              setState(() {
                widget.isDarkMode = !widget.isDarkMode;
              });
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

          var allDocs = snapshot.data!.docs;
          Set<String> allTags = Set<String>();

          var filteredDocs = allDocs.where((doc) {
            Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
            List<String> noteTags = List<String>.from(data['tags'] ?? []);

            allTags.addAll(noteTags);

            bool matchesSearch = data['title']
                    .toString()
                    .toLowerCase()
                    .contains(_searchQuery) ||
                data['content'].toString().toLowerCase().contains(_searchQuery);

            bool matchesTags = _selectedTags.isEmpty ||
                _selectedTags.every((tag) => noteTags.contains(tag));

            return matchesSearch && matchesTags;
          }).toList();

          filteredDocs.sort((a, b) {
            bool isPinnedA =
                (a.data() as Map<String, dynamic>)['pinned'] ?? false;
            bool isPinnedB =
                (b.data() as Map<String, dynamic>)['pinned'] ?? false;
            if (isPinnedA != isPinnedB) {
              return isPinnedA ? -1 : 1;
            }
            Timestamp timestampA =
                (a.data() as Map<String, dynamic>)['timestamp'] ??
                    Timestamp.now();
            Timestamp timestampB =
                (b.data() as Map<String, dynamic>)['timestamp'] ??
                    Timestamp.now();
            return timestampB.compareTo(timestampA);
          });

          if (filteredDocs.isEmpty) {
            return Center(child: Text('No matching notes found'));
          }

          return Column(
            children: [
              _buildTagFilter(allTags.toList()),
              Expanded(
                child: ListView.builder(
                  itemCount: filteredDocs.length,
                  itemBuilder: (context, index) {
                    Map<String, dynamic> data =
                        filteredDocs[index].data() as Map<String, dynamic>;
                    Color noteColor =
                        Color(data['color'] ?? Colors.white.value);
                    Color textColor = getTextColor(noteColor);
                    bool isPinned = data['pinned'] ?? false;
                    return GestureDetector(
                      onLongPress: () => _showOptionsDialog(
                          context, filteredDocs[index].id, isPinned),
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
                      child: Card(
                        elevation: 2,
                        margin:
                            EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        color: noteColor,
                        child: Stack(
                          children: [
                            ListTile(
                              title: Text(
                                data['title'] ?? 'No Title',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: textColor),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    data['content'] ?? 'No Content',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(color: textColor),
                                  ),
                                  SizedBox(height: 4),
                                  Wrap(
                                    spacing: 4,
                                    children:
                                        (data['tags'] as List<dynamic>? ?? [])
                                            .map<Widget>((tag) {
                                      return Chip(
                                        label: Text(tag,
                                            style: TextStyle(fontSize: 10)),
                                        backgroundColor: Theme.of(context)
                                            .primaryColor
                                            .withOpacity(0.1),
                                        padding: EdgeInsets.all(0),
                                        materialTapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ),
                              leading: CircleAvatar(
                                backgroundColor: textColor,
                                child: Text(
                                  (data['title'] ?? 'N')[0].toUpperCase(),
                                  style: TextStyle(color: noteColor),
                                ),
                              ),
                            ),
                            if (isPinned)
                              Positioned(
                                top: 4,
                                left: 4,
                                child: Icon(
                                  Icons.push_pin,
                                  color: textColor,
                                  size: 20,
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
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
