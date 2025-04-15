import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:meetme/api_service.dart';

class StudentPage5 extends StatefulWidget {
  final String senderId;
  final String receiverId;
  final String receiverName;

  const StudentPage5({
    super.key,
    required this.senderId,
    required this.receiverId,
    required this.receiverName,
  });

  @override
  State<StudentPage5> createState() => _StudentPage5State();
}

class _StudentPage5State extends State<StudentPage5> {
  late WebSocketChannel _channel;
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Map<String, dynamic>> messages = [];

  @override
  void initState() {
    super.initState();
    _channel = WebSocketChannel.connect(
      //Uri.parse('ws://127.0.0.1:8000/ws/chat/${widget.senderId}'),
      Uri.parse('ws://192.168.12.223:8000/ws/chat/${widget.senderId}'),
    );

    _channel.stream.listen((data) {
      final decoded = jsonDecode(data);
      if ((decoded['sender_id'] == widget.receiverId &&
              decoded['receiver_id'] == widget.senderId) ||
          decoded['sender_id'] == widget.senderId) {
        setState(() {
          messages.add(decoded);
        });
        _scrollToBottom();
      }
    });

    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final history =
        await ApiService.getChatHistory(widget.senderId, widget.receiverId);
    setState(() => messages = history);
    await Future.delayed(const Duration(milliseconds: 200));
    _scrollToBottom();
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final msg = {
      'sender_id': widget.senderId,
      'receiver_id': widget.receiverId,
      'message': text,
    };

    _channel.sink.add(jsonEncode(msg));

    setState(() {
      messages.add(msg);
    });

    _controller.clear();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 60,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void dispose() {
    _channel.sink.close();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text("Chat with ${widget.receiverName}"),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: Theme.of(context).shadowColor),
        titleTextStyle: TextStyle(
          color: Theme.of(context).shadowColor,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          fontFamily: 'Poppins',
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(12),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final msg = messages[index];
                final isMe = msg['sender_id'] == widget.senderId;
                final alignment =
                    isMe ? Alignment.centerRight : Alignment.centerLeft;
                final bubbleColor = isMe
                    ? Theme.of(context).colorScheme.secondary.withOpacity(0.9)
                    : Theme.of(context).cardColor.withOpacity(0.9);

                final textColor = isMe
                    ? Colors.white
                    : Theme.of(context).textTheme.bodyMedium!.color;

                return Align(
                  alignment: alignment,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: bubbleColor,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      msg['message'],
                      style: TextStyle(fontSize: 15, color: textColor),
                    ),
                  ),
                );
              },
            ),
          ),
          Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    onSubmitted: (_) => _sendMessage(),
                    decoration: InputDecoration(
                      hintText: 'Type your message...',
                      filled: true,
                      fillColor: Theme.of(context).cardColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 10, horizontal: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                CircleAvatar(
                  backgroundColor: Theme.of(context).primaryColor,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
