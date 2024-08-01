import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:my_notes_app/Screens/NotesDetailsScreen.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:animated_text_kit/animated_text_kit.dart';

class LockedNotesScreen extends StatefulWidget {
  @override
  _LockedNotesScreenState createState() => _LockedNotesScreenState();
}

class _LockedNotesScreenState extends State<LockedNotesScreen> {
  String _searchQuery = '';
  bool _isSearching = false;
  Set<String> _selectedTags = Set<String>();
  Color? _selectedColor;

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
              selectedColor: Theme.of(context).primaryColor.withOpacity(0.7),
              checkmarkColor: Colors.white,
              labelStyle: TextStyle(color: Colors.black),
              backgroundColor: Colors.grey[200],
            ),
          );
        },
      ),
    );
  }

  void _showColorFilterDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Filter by Color'),
          content: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildColorOption(null, 'All'),
              _buildColorOption(Colors.white, 'White'),
              _buildColorOption(Colors.red[100]!, 'Red'),
              _buildColorOption(Colors.blue[100]!, 'Blue'),
              _buildColorOption(Colors.green[100]!, 'Green'),
              _buildColorOption(Colors.yellow[100]!, 'Yellow'),
              _buildColorOption(Colors.purple[100]!, 'Purple'),
            ],
          ),
        );
      },
    );
  }

  Widget _buildColorOption(Color? color, String label) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedColor = color;
        });
        Navigator.of(context).pop();
      },
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: color ?? Colors.transparent,
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: color == null ? Colors.black : getTextColor(color),
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  void _unlockNote(String noteId, Map<String, dynamic> noteData) async {
    final user = FirebaseAuth.instance.currentUser!;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('notes')
          .doc(noteId)
          .update({'isLocked': false});

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Note has been unlocked')),
      );

      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to unlock note: $e')),
      );
    }
  }

  void _showNoteOptions(
      BuildContext context, String noteId, Map<String, dynamic> noteData) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: Icon(Icons.lock_open),
                title: Text('Unlock Note'),
                onTap: () {
                  Navigator.pop(context);
                  _unlockNote(noteId, noteData);
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
                  hintText: 'Search locked notes...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Colors.white70),
                ),
                style: TextStyle(color: Colors.white),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.toLowerCase();
                  });
                },
              )
            : AnimatedTextKit(
                animatedTexts: [
                  TypewriterAnimatedText(
                    'Locked Notes',
                    textStyle: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    speed: Duration(milliseconds: 200),
                  ),
                ],
                totalRepeatCount: 1,
              ),
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
            icon: Icon(Icons.color_lens),
            onPressed: _showColorFilterDialog,
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('notes')
            .where('isLocked', isEqualTo: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Something went wrong'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock, size: 100, color: Colors.grey),
                  SizedBox(height: 20),
                  Text(
                    'No locked notes yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            );
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

            bool matchesColor = _selectedColor == null ||
                Color(data['color'] ?? Colors.white.value) == _selectedColor;

            return matchesSearch && matchesTags && matchesColor;
          }).toList();

          return Column(
            children: [
              _buildTagFilter(allTags.toList()),
              Expanded(
                child: filteredDocs.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off,
                                size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              'No locked notes found',
                              style:
                                  TextStyle(fontSize: 18, color: Colors.grey),
                            ),
                            if (_selectedTags.isNotEmpty ||
                                _selectedColor != null)
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    _selectedTags.clear();
                                    _selectedColor = null;
                                  });
                                },
                                child: Text('Clear filters'),
                              ),
                          ],
                        ),
                      )
                    : MasonryGridView.count(
                        crossAxisCount: 2,
                        itemCount: filteredDocs.length,
                        itemBuilder: (context, index) {
                          Map<String, dynamic> data = filteredDocs[index].data()
                              as Map<String, dynamic>;
                          Color noteColor =
                              Color(data['color'] ?? Colors.white.value);
                          Color textColor = getTextColor(noteColor);
                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => NoteDetailScreen(
                                    note: data,
                                    noteId: filteredDocs[index].id,
                                  ),
                                ),
                              );
                            },
                            onLongPress: () {
                              _showNoteOptions(
                                  context, filteredDocs[index].id, data);
                            },
                            child: Card(
                              elevation: 4,
                              margin: EdgeInsets.all(8),
                              color: noteColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Padding(
                                padding: EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      data['title'] ?? 'No Title',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: textColor,
                                        fontSize: 18,
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      data['content'] ?? 'No Content',
                                      maxLines: 5,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(color: textColor),
                                    ),
                                    SizedBox(height: 8),
                                    Wrap(
                                      spacing: 4,
                                      runSpacing: 4,
                                      children:
                                          (data['tags'] as List<dynamic>? ?? [])
                                              .map<Widget>((tag) {
                                        return Chip(
                                          label: Text(tag,
                                              style: TextStyle(fontSize: 10)),
                                          backgroundColor: Theme.of(context)
                                              .primaryColor
                                              .withOpacity(0.1),
                                          padding: EdgeInsets.all(4),
                                          materialTapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                        );
                                      }).toList(),
                                    ),
                                  ],
                                ),
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
    );
  }
}
