import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:my_notes_app/Auth/ResetPin';
import 'package:my_notes_app/Screens/LockedNotes.dart';
import 'package:my_notes_app/Screens/NoteAddScreen.dart';
import 'package:my_notes_app/Screens/NotesDetailsScreen.dart';
import 'package:my_notes_app/Screens/NoteEditScreen.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:animated_text_kit/animated_text_kit.dart';

class NotesScreen extends StatefulWidget {
  final Function toggleTheme;
  bool isDarkMode;

  NotesScreen({required this.toggleTheme, required this.isDarkMode});

  @override
  _NotesScreenState createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen>
    with TickerProviderStateMixin {
  String _searchQuery = '';
  bool _isSearching = false;
  Set<String> _selectedTags = Set<String>();
  late AnimationController _fabAnimationController;
  late Animation<double> _fabAnimation;
  Color? _selectedColor;
  String _currentView = 'notes'; // 'notes', 'archive', or 'trash'

  @override
  void initState() {
    super.initState();
    _fabAnimationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    );
    _fabAnimation = CurvedAnimation(
      parent: _fabAnimationController,
      curve: Curves.easeInOut,
    );
    _startPeriodicCleanup();
    _checkPinExists();
  }

  @override
  void dispose() {
    _fabAnimationController.dispose();
    super.dispose();
  }

  Future<void> _launchgitUrl() async {
    Uri.parse('https://github.com/Piyu-Pika/my_notes_app');
  }

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
      child: Row(
        children: [
          Expanded(
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
                    selectedColor:
                        Theme.of(context).primaryColor.withOpacity(0.7),
                    checkmarkColor: Colors.white,
                    labelStyle: TextStyle(
                      color: widget.isDarkMode ? Colors.white : Colors.black,
                    ),
                    backgroundColor:
                        widget.isDarkMode ? Colors.grey[800] : Colors.grey[200],
                  ),
                );
              },
            ),
          ),
          if (_selectedTags.isNotEmpty)
            IconButton(
              icon: Icon(Icons.clear),
              onPressed: () {
                setState(() {
                  _selectedTags.clear();
                });
              },
              tooltip: 'Clear all filters',
            ),
        ],
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

  void _archiveNote(String noteId) {
    final user = FirebaseAuth.instance.currentUser!;
    FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('notes')
        .doc(noteId)
        .update({'archived': true}).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Note archived')),
      );
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to archive note: $error')),
      );
    });
  }

  void _moveToTrash(String noteId) {
    final user = FirebaseAuth.instance.currentUser!;
    FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('notes')
        .doc(noteId)
        .update({
      'inTrash': true,
      'trashDate': FieldValue.serverTimestamp(),
    }).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Note moved to trash')),
      );
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to move note to trash: $error')),
      );
    });
  }

  void _restoreFromTrash(String noteId) {
    final user = FirebaseAuth.instance.currentUser!;
    FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('notes')
        .doc(noteId)
        .update({
      'inTrash': false,
      'trashDate': FieldValue.delete(),
    }).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Note restored from trash')),
      );
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to restore note: $error')),
      );
    });
  }

  void _deleteNotePermanently(String noteId) {
    final user = FirebaseAuth.instance.currentUser!;
    FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('notes')
        .doc(noteId)
        .delete()
        .then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Note permanently deleted')),
      );
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete note: $error')),
      );
    });
  }

  void _lockNote(String noteId, Map<String, dynamic> noteData) async {
    final user = FirebaseAuth.instance.currentUser!;

    // First, verify the PIN
    String? enteredPin = await _promptForPin('Enter PIN to lock note');
    if (enteredPin == null) return; // User cancelled

    try {
      // Verify the entered PIN
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        String? storedPin =
            (doc.data() as Map<String, dynamic>)['lockedNotesPin'];
        if (storedPin != enteredPin) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Incorrect PIN')),
          );
          return;
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User data not found')),
        );
        return;
      }

      // PIN is correct, proceed to lock the note
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('notes')
          .doc(noteId)
          .update({
        'isLocked': true,
        'archived': false,
        'inTrash': false,
        'pinned': false,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Note has been locked')),
      );

      // Refresh the screen
      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to lock note: $e')),
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
              if (_currentView == 'notes') ...[
                ListTile(
                  leading: Icon(Icons.edit),
                  title: Text('Edit'),
                  onTap: () {
                    Navigator.pop(context);
                    _editNote(context, noteId, noteData);
                  },
                ),
                ListTile(
                  leading: Icon(noteData['pinned'] ?? false
                      ? Icons.push_pin
                      : Icons.push_pin_outlined),
                  title: Text(noteData['pinned'] ?? false ? 'Unpin' : 'Pin'),
                  onTap: () {
                    Navigator.pop(context);
                    _togglePinNote(noteId, noteData['pinned'] ?? false);
                  },
                ),
                ListTile(
                  leading: Icon(Icons.lock),
                  title: Text('Lock Note'),
                  onTap: () {
                    Navigator.pop(context);
                    _lockNote(noteId, noteData);
                  },
                ),
                ListTile(
                  leading: Icon(Icons.archive),
                  title: Text('Archive'),
                  onTap: () {
                    Navigator.pop(context);
                    _archiveNote(noteId);
                  },
                ),
                ListTile(
                  leading: Icon(Icons.delete),
                  title: Text('Move to Trash'),
                  onTap: () {
                    Navigator.pop(context);
                    _moveToTrash(noteId);
                  },
                ),
              ] else if (_currentView == 'archive') ...[
                ListTile(
                  leading: Icon(Icons.unarchive),
                  title: Text('Unarchive'),
                  onTap: () {
                    Navigator.pop(context);
                    FirebaseFirestore.instance
                        .collection('users')
                        .doc(FirebaseAuth.instance.currentUser!.uid)
                        .collection('notes')
                        .doc(noteId)
                        .update({'archived': false});
                  },
                ),
                ListTile(
                  leading: Icon(Icons.delete),
                  title: Text('Move to Trash'),
                  onTap: () {
                    Navigator.pop(context);
                    _moveToTrash(noteId);
                  },
                ),
              ] else if (_currentView == 'trash') ...[
                ListTile(
                  leading: Icon(Icons.restore),
                  title: Text('Restore'),
                  onTap: () {
                    Navigator.pop(context);
                    _restoreFromTrash(noteId);
                  },
                ),
                ListTile(
                  leading: Icon(Icons.delete_forever),
                  title: Text('Delete Permanently'),
                  onTap: () {
                    Navigator.pop(context);
                    _deleteNotePermanently(noteId);
                  },
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  void _editNote(
      BuildContext context, String noteId, Map<String, dynamic> noteData) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditNoteScreen(note: noteData, noteId: noteId),
      ),
    ).then((updatedNote) {
      if (updatedNote != null) {
        setState(() {
          // Update the local state if necessary
        });
      }
    });
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
              color: color == null
                  ? (widget.isDarkMode ? Colors.white : Colors.black)
                  : getTextColor(color),
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  void _checkPinExists() async {
    final user = FirebaseAuth.instance.currentUser!;
    final docSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    if (!docSnapshot.exists ||
        !docSnapshot.data()!.containsKey('lockedNotesPin')) {
      // Document doesn't exist or PIN doesn't exist, prompt user to create one
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showCreatePinDialog();
      });
    }
  }

  void _showCreatePinDialog() {
    String enteredPin = '';
    String confirmedPin = '';
    bool isConfirming = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            title: Text(isConfirming ? 'Confirm PIN' : 'Create PIN'),
            content: TextField(
              keyboardType: TextInputType.number,
              maxLength: 4,
              obscureText: true,
              onChanged: (value) {
                if (isConfirming) {
                  confirmedPin = value;
                } else {
                  enteredPin = value;
                }
              },
              decoration: InputDecoration(
                hintText:
                    isConfirming ? 'Confirm 4-digit PIN' : 'Enter 4-digit PIN',
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: Text('Cancel'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              TextButton(
                child: Text(isConfirming ? 'Confirm' : 'Next'),
                onPressed: () {
                  if (isConfirming) {
                    if (enteredPin == confirmedPin) {
                      Navigator.of(context).pop();
                      _savePin(enteredPin);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content:
                                Text('PINs do not match. Please try again.')),
                      );
                      setState(() {
                        isConfirming = false;
                        confirmedPin = '';
                      });
                    }
                  } else {
                    if (enteredPin.length == 4) {
                      setState(() {
                        isConfirming = true;
                      });
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Please enter a 4-digit PIN.')),
                      );
                    }
                  }
                },
              ),
            ],
          );
        });
      },
    );
  }

  void _savePin(String pin) async {
    final user = FirebaseAuth.instance.currentUser!;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .set({'lockedNotesPin': pin}, SetOptions(merge: true));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('PIN has been set successfully')),
    );
  }

  void _showPinDialog() {
    String enteredPin = '';
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Enter PIN'),
          content: TextField(
            keyboardType: TextInputType.number,
            maxLength: 4,
            obscureText: true,
            onChanged: (value) {
              enteredPin = value;
            },
            decoration: InputDecoration(
              hintText: 'Enter 4-digit PIN',
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Enter'),
              onPressed: () {
                Navigator.of(context).pop();
                _verifyPin(enteredPin);
              },
            ),
          ],
        );
      },
    );
  }

  void _verifyPin(String enteredPin) async {
    final user = FirebaseAuth.instance.currentUser!;
    final docSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    if (docSnapshot.exists) {
      final data = docSnapshot.data() as Map<String, dynamic>;
      final storedPin = data['lockedNotesPin'] as String?;

      if (storedPin == enteredPin) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => LockedNotesScreen()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Incorrect PIN')),
        );
      }
    }
  }

  Future<String?> _promptForPin(String message) async {
    String? pin;
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(message),
          content: TextField(
            keyboardType: TextInputType.number,
            maxLength: 4,
            obscureText: true,
            onChanged: (value) {
              pin = value;
            },
            decoration: InputDecoration(
              hintText: 'Enter 4-digit PIN',
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
                pin = null;
              },
            ),
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
    return pin;
  }

  void _resetPin() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ResetPinScreen()),
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
            : AnimatedTextKit(
                animatedTexts: [
                  TypewriterAnimatedText(
                    _currentView == 'notes'
                        ? 'My Notes'
                        : _currentView == 'archive'
                            ? 'Archive'
                            : 'Trash',
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
          IconButton(
            icon: Icon(widget.isDarkMode ? Icons.light_mode : Icons.dark_mode),
            onPressed: () {
              setState(() {
                widget.isDarkMode = !widget.isDarkMode;
              });
              widget.toggleTheme();
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
              ),
              child: Text(
                'Note App',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            ListTile(
              leading: Icon(Icons.note),
              title: Text('Notes'),
              onTap: () {
                setState(() {
                  _currentView = 'notes';
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.lock),
              title: Text('Locked Notes'),
              onTap: () {
                Navigator.pop(context);
                _showPinDialog();
              },
            ),
            ListTile(
              leading: Icon(Icons.archive),
              title: Text('Archive'),
              onTap: () {
                setState(() {
                  _currentView = 'archive';
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.delete),
              title: Text('Trash'),
              onTap: () {
                setState(() {
                  _currentView = 'trash';
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.share),
              title: Text('Share App'),
              onTap: () {
                _launchgitUrl();
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.lock_reset),
              title: Text('Reset Locked Notes PIN'),
              onTap: () {
                Navigator.pop(context);
                _resetPin();
              },
            ),
            Divider(),
            ListTile(
              leading: Icon(Icons.logout),
              title: Text('Logout'),
              onTap: () {
                Navigator.pop(context);
                _showLogoutConfirmationDialog();
              },
            ),
          ],
        ),
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
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.note_add, size: 100, color: Colors.grey),
                  SizedBox(height: 20),
                  Text(
                    'No notes yet. Add your first note!',
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

            // Add this condition to filter out locked notes
            if (data['isLocked'] == true) return false;

            bool matchesSearch = data['title']
                    .toString()
                    .toLowerCase()
                    .contains(_searchQuery) ||
                data['content'].toString().toLowerCase().contains(_searchQuery);

            bool matchesTags = _selectedTags.isEmpty ||
                _selectedTags.every((tag) => noteTags.contains(tag));

            bool matchesColor = _selectedColor == null ||
                Color(data['color'] ?? Colors.white.value) == _selectedColor;

            bool matchesView = (_currentView == 'notes' &&
                    !(data['archived'] ?? false) &&
                    !(data['inTrash'] ?? false)) ||
                (_currentView == 'archive' && (data['archived'] ?? false)) ||
                (_currentView == 'trash' && (data['inTrash'] ?? false));

            return matchesSearch && matchesTags && matchesColor && matchesView;
          }).toList();

          // Sort notes
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
                              'No ${_currentView == 'notes' ? 'notes' : _currentView == 'archive' ? 'archived notes' : 'items in trash'} found',
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
                          bool isPinned = data['pinned'] ?? false;
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
                                    if (isPinned && _currentView == 'notes')
                                      Align(
                                        alignment: Alignment.topRight,
                                        child: Icon(
                                          Icons.push_pin,
                                          color: textColor,
                                          size: 20,
                                        ),
                                      ),
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
                                    if (_currentView == 'trash')
                                      Text(
                                        'Deleted on: ${_formatDate(data['trashDate'])}',
                                        style: TextStyle(
                                          color: textColor.withOpacity(0.7),
                                          fontSize: 12,
                                        ),
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
      floatingActionButton: _currentView == 'notes'
          ? ScaleTransition(
              scale: _fabAnimation,
              child: FloatingActionButton.extended(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => AddNoteScreen()),
                  );
                },
                icon: Icon(Icons.add),
                label: Text('Add Note'),
              ),
            )
          : null,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _fabAnimationController.forward();
  }

  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) return 'Unknown';
    DateTime date = timestamp.toDate();
    return '${date.day}/${date.month}/${date.year}';
  }

  // Add this method to periodically clean up old trash items
  void _cleanupTrash() {
    final user = FirebaseAuth.instance.currentUser!;
    FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('notes')
        .where('inTrash', isEqualTo: true)
        .get()
        .then((querySnapshot) {
      for (var doc in querySnapshot.docs) {
        Timestamp? trashDate = doc.data()['trashDate'];
        if (trashDate != null) {
          Duration difference = DateTime.now().difference(trashDate.toDate());
          if (difference.inDays > 30) {
            _deleteNotePermanently(doc.id);
          }
        }
      }
    });
  }

  // Call this method in initState() to start periodic cleanup
  void _startPeriodicCleanup() {
    Future.delayed(Duration(days: 1), () {
      _cleanupTrash();
      _startPeriodicCleanup();
    });
  }
}
