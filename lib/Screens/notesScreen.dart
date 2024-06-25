import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:my_notes_app/Screens/NoteAddScreen.dart';
import 'package:my_notes_app/Screens/NotesDetailsScreen.dart';

class NotesScreen extends StatefulWidget {
  @override
  _NotesScreenState createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  String _searchQuery = '';

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Search Notes'),
          content: TextField(
            onChanged: (value) {
              setState(() {
                _searchQuery = value.toLowerCase();
              });
            },
            decoration: const InputDecoration(
              hintText: 'Enter search term...',
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                setState(() {
                  _searchQuery = '';
                });
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Search'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _showSearchDialog,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => FirebaseAuth.instance.signOut(),
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
            return const Center(child: Text('Something went wrong'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
                child: Text('No notes yet. Add your first note!'));
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
            return const Center(child: Text('No matching notes found'));
          }

          return ListView(
            children: filteredDocs.map((DocumentSnapshot document) {
              Map<String, dynamic> data =
                  document.data()! as Map<String, dynamic>;
              return ListTile(
                title: Text(data['title'] ?? 'No Title'),
                subtitle: Text(
                  data['content'] ?? 'No Content',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          NoteDetailScreen(note: data, noteId: document.id),
                    ),
                  );
                },
              );
            }).toList(),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
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
