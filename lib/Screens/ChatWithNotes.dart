import 'package:flutter/material.dart';
import 'package:flutter_gemini/flutter_gemini.dart';

class NoteChatScreen extends StatefulWidget {
  final String noteContent;
  final String noteTitle;

  const NoteChatScreen(
      {Key? key, required this.noteContent, required this.noteTitle})
      : super(key: key);

  @override
  _NoteChatScreenState createState() => _NoteChatScreenState();
}

class _NoteChatScreenState extends State<NoteChatScreen> {
  final _textController = TextEditingController();
  final gemini = Gemini.instance;
  final List<ChatMessage> _messages = [];

  Future<void> _sendMessage() async {
    if (_textController.text.isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(
        text: _textController.text,
        isUser: true,
      ));
    });

    String prompt = '''
    Based on the following note content:
    ${widget.noteContent}
    
    Please respond to this user query:
    ${_textController.text}
    
    Respond as if you're an AI assistant discussing this note.
    ''';

    final response = await gemini.text(prompt);
    setState(() {
      _messages.add(ChatMessage(
        text: response?.content?.parts?.last.text ??
            'Sorry, I could not process that.',
        isUser: false,
      ));
    });

    _textController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chat about: ${widget.noteTitle}'),
        centerTitle: true,
      ),
      body: Center(
        child: Container(
          constraints: BoxConstraints(maxWidth: 800),
          child: Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    return _messages[index];
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _textController,
                        decoration: InputDecoration(
                          hintText: 'Ask about your note...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25.0),
                          ),
                          filled: true,
                          fillColor: Colors.grey[200],
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send),
                      onPressed: _sendMessage,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ChatMessage extends StatelessWidget {
  final String text;
  final bool isUser;

  const ChatMessage({Key? key, required this.text, required this.isUser})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) CircleAvatar(child: Text('AI')),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: isUser ? Colors.blue[100] : Colors.grey[300],
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Text(text),
                ),
              ],
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 10),
            const CircleAvatar(child: Icon(Icons.person)),
          ],
        ],
      ),
    );
  }
}
