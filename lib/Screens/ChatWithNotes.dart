import 'package:flutter/material.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';

class NoteChatScreen extends StatefulWidget {
  final String noteContent;
  final String noteTitle;
  final String noteId;

  const NoteChatScreen({
    Key? key,
    required this.noteContent,
    required this.noteTitle,
    required this.noteId,
  }) : super(key: key);

  @override
  _NoteChatScreenState createState() => _NoteChatScreenState();
}

class _NoteChatScreenState extends State<NoteChatScreen> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  final gemini = Gemini.instance;
  List<ChatMessage> _messages = [];
  bool _isLoading = false;
  bool _showCommands = false;
  final List<String> _commands = ['/edit', '/update', '/rewrite', '/addemoji'];
  String? _lastPrompt;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _textController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _textController.removeListener(_onTextChanged);
    _textController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    setState(() {
      _showCommands = _textController.text == '/';
    });
  }

  Future<void> _loadMessages() async {
    final prefs = await SharedPreferences.getInstance();
    final String? messagesJson =
        prefs.getString('chat_messages_${widget.noteTitle}');
    if (messagesJson != null) {
      setState(() {
        _messages = (jsonDecode(messagesJson) as List)
            .map((item) => ChatMessage.fromJson(item))
            .toList();
      });
    } else {
      _addInitialMessage();
    }
  }

  Future<void> _saveMessages() async {
    final prefs = await SharedPreferences.getInstance();
    final String messagesJson =
        jsonEncode(_messages.map((m) => m.toJson()).toList());
    await prefs.setString('chat_messages_${widget.noteTitle}', messagesJson);
  }

  void _addInitialMessage() {
    setState(() {
      _messages.add(ChatMessage(
        text:
            "Hello! I'm here to help you with your note titled '${widget.noteTitle}'. What would you like to know?",
        isUser: false,
      ));
    });
    _saveMessages();
  }

  Future<void> _sendMessage() async {
    if (_textController.text.isEmpty) return;

    String userInput = _textController.text;
    setState(() {
      _messages.add(
        ChatMessage(
          text: userInput,
          isUser: true,
        ),
      );
      _isLoading = true;
      _textController.clear();
      _showCommands = false;
    });

    _scrollToBottom();
    _saveMessages();

    String prompt;
    bool isEditing = false;
    if (userInput.startsWith('/')) {
      String command = userInput.split(' ')[0].toLowerCase();
      String restOfInput = userInput.substring(command.length).trim();
      switch (command) {
        case '/edit':
        case '/update':
        case '/rewrite':
        case '/addemoji':
          isEditing = true;
          prompt =
              '$command the following note content based on this instruction: $restOfInput\n\nOriginal content:\n${widget.noteContent}';
          break;
        default:
          prompt = '''
          Based on the following note content:
          ${widget.noteContent}
          
          Please respond to this user query:
          $userInput
          
          Respond as if you're an AI assistant discussing this note.
          You can also use internet information if needed or information not in the notes itself.
          ''';
      }
    } else {
      prompt = '''
      Based on the following note content:
      ${widget.noteContent}
      
      Please respond to this user query:
      $userInput
      
      Respond as if you're an AI assistant discussing this note.
      You can also use internet information if needed or information not in the notes itself.
      ''';
    }

    _lastPrompt = prompt;

    try {
      final response = await gemini.text(prompt);
      setState(() {
        _messages.add(ChatMessage(
          text: response?.content?.parts?.last.text ??
              'Sorry, I could not process that.',
          isUser: false,
          showActions: isEditing,
          onConfirm: () => _updateNoteInFirebase(_messages.last.text),
          onReject: () => _removeLastMessage(),
          onRetry: () => _retryLastPrompt(),
        ));
        _isLoading = false;
      });
      _saveMessages();
    } catch (e) {
      setState(() {
        _messages.add(ChatMessage(
          text: 'An error occurred. Please try again.',
          isUser: false,
        ));
        _isLoading = false;
      });
      _saveMessages();
    }

    _scrollToBottom();
  }

  void _updateNoteInFirebase(String newContent) async {
    final user = FirebaseAuth.instance.currentUser!;
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('notes')
          .doc(widget.noteId)
          .update({
        'content': newContent,
        'timestamp': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Note updated successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update note: $e')),
      );
    }
  }

  void _removeLastMessage() {
    setState(() {
      _messages.removeLast();
    });
    _saveMessages();
  }

  void _retryLastPrompt() {
    if (_lastPrompt != null) {
      _removeLastMessage();
      _sendMessageWithPrompt(_lastPrompt!);
    }
  }

  Future<void> _sendMessageWithPrompt(String prompt) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await gemini.text(prompt);
      setState(() {
        _messages.add(ChatMessage(
          text: response?.content?.parts?.last.text ??
              'Sorry, I could not process that.',
          isUser: false,
          showActions: true,
          onConfirm: () => _updateNoteInFirebase(_messages.last.text),
          onReject: () => _removeLastMessage(),
          onRetry: () => _retryLastPrompt(),
        ));
        _isLoading = false;
      });
      _saveMessages();
    } catch (e) {
      setState(() {
        _messages.add(ChatMessage(
          text: 'An error occurred. Please try again.',
          isUser: false,
        ));
        _isLoading = false;
      });
      _saveMessages();
    }

    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('Chat: ${widget.noteTitle}'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  return _messages[index];
                },
              ),
            ),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: CircularProgressIndicator(),
              ),
            if (_showCommands)
              Container(
                color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                child: Column(
                  children: _commands
                      .map((command) => ListTile(
                            title: Text(command),
                            onTap: () {
                              setState(() {
                                _textController.text = command + ' ';
                                _textController.selection =
                                    TextSelection.fromPosition(
                                  TextPosition(
                                      offset: _textController.text.length),
                                );
                                _showCommands = false;
                              });
                            },
                          ))
                      .toList(),
                ),
              ),
            Container(
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey[900] : Colors.grey[100],
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 5,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _textController,
                        decoration: InputDecoration(
                          hintText: 'Ask about your note or use /commands...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25.0),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor:
                              isDarkMode ? Colors.grey[800] : Colors.white,
                          hintStyle: TextStyle(
                            color: isDarkMode
                                ? Colors.grey[400]
                                : Colors.grey[600],
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                        ),
                        style: TextStyle(
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                        maxLines: null,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.send),
                      onPressed: _sendMessage,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ChatMessage extends StatelessWidget {
  final String text;
  final bool isUser;
  final bool showActions;
  final VoidCallback? onConfirm;
  final VoidCallback? onReject;
  final VoidCallback? onRetry;

  const ChatMessage({
    Key? key,
    required this.text,
    required this.isUser,
    this.showActions = false,
    this.onConfirm,
    this.onReject,
    this.onRetry,
  }) : super(key: key);

  Map<String, dynamic> toJson() => {
        'text': text,
        'isUser': isUser,
        'showActions': showActions,
      };

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        text: json['text'],
        isUser: json['isUser'],
        showActions: json['showActions'] ?? false,
      );

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final userBubbleColor = isDarkMode ? Colors.blue[700] : Colors.blue[100];
    final aiBubbleColor = isDarkMode ? Colors.grey[700] : Colors.grey[300];
    final textColor = isDarkMode ? Colors.white : Colors.black;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Column(
        crossAxisAlignment:
            isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment:
                isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isUser) ...[
                CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                  child: const Icon(Icons.assistant, color: Colors.white),
                ),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isUser ? userBubbleColor : aiBubbleColor,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isUser ? 16 : 0),
                      bottomRight: Radius.circular(isUser ? 0 : 16),
                    ),
                  ),
                  child: Text(
                    text,
                    style: TextStyle(color: textColor),
                  ),
                ),
              ),
              if (isUser) ...[
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: const Icon(Icons.person, color: Colors.white),
                ),
              ],
            ],
          ),
          if (showActions && !isUser)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: const Icon(Icons.check, color: Colors.green),
                    onPressed: onConfirm,
                    tooltip: 'Confirm',
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.red),
                    onPressed: onReject,
                    tooltip: 'Reject',
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh, color: Colors.blue),
                    onPressed: onRetry,
                    tooltip: 'Retry',
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
