import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_gemini/flutter_gemini.dart';

class AddNoteScreen extends StatefulWidget {
  @override
  _AddNoteScreenState createState() => _AddNoteScreenState();
}

class _AddNoteScreenState extends State<AddNoteScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _linkController = TextEditingController();
  bool _isLoading = false;
  final gemini = Gemini.instance;
  Color _selectedColor = Colors.white;

  final List<Color> _colorOptions = [
    Colors.white,
    Colors.red[100]!,
    Colors.blue[100]!,
    Colors.green[100]!,
    Colors.yellow[100]!,
    Colors.purple[100]!,
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _linkController.dispose();
    super.dispose();
  }

  Future<void> _generateTitle() async {
    // ... (keep the existing _generateTitle method)
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final user = FirebaseAuth.instance.currentUser!;
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('notes')
            .add({
          'title': _titleController.text.trim(),
          'content': _contentController.text.trim(),
          'link': _linkController.text.trim(),
          'timestamp': FieldValue.serverTimestamp(),
          'color': _selectedColor.value,
        });

        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Note added successfully')),
        );
      } catch (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add note: $error')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('Add Note'),
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: _isLoading ? null : _submitForm,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      Card(
                        elevation: 4,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: TextFormField(
                            controller: _titleController,
                            decoration: InputDecoration(
                              labelText: 'Title',
                              border: InputBorder.none,
                              suffixIcon: IconButton(
                                icon: Icon(Icons.auto_awesome_rounded),
                                onPressed: _generateTitle,
                                tooltip: 'Generate title',
                              ),
                            ),
                            validator: (value) =>
                                value!.isEmpty ? 'Please enter a title' : null,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 16),
                      Card(
                        elevation: 4,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: TextFormField(
                            controller: _contentController,
                            decoration: InputDecoration(
                              labelText: 'Content',
                              border: InputBorder.none,
                            ),
                            validator: (value) => value!.isEmpty
                                ? 'Please enter some content'
                                : null,
                            maxLines: 15,
                            keyboardType: TextInputType.multiline,
                          ),
                        ),
                      ),
                      SizedBox(height: 16),
                      Card(
                        elevation: 4,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: TextFormField(
                            controller: _linkController,
                            decoration: InputDecoration(
                              labelText: 'Link (optional)',
                              border: InputBorder.none,
                              prefixIcon: Icon(Icons.link),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 16),
                      Card(
                        elevation: 4,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Note Color',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                children: _colorOptions.map((Color color) {
                                  return GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _selectedColor = color;
                                      });
                                    },
                                    child: Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: color,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: _selectedColor == color
                                              ? Colors.black
                                              : Colors.grey,
                                          width: 2,
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 20),
                      ElevatedButton.icon(
                        icon: Icon(
                          Icons.save,
                          color: isDarkMode ? Colors.white : Colors.black87,
                        ),
                        label: Text(
                          'Save Note',
                          style: TextStyle(
                            color: isDarkMode ? Colors.white : Colors.black87,
                          ),
                        ),
                        onPressed: _isLoading ? null : _submitForm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          padding: EdgeInsets.symmetric(
                              horizontal: 40, vertical: 15),
                          textStyle: TextStyle(
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
