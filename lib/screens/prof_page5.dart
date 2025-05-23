import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:meetme/api_service.dart';

class ChatScreen extends StatefulWidget {
  final String senderId;
  final String receiverId;
  final String receiverName;

  const ChatScreen({
    super.key,
    required this.senderId,
    required this.receiverId,
    required this.receiverName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late WebSocketChannel _channel;
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Map<String, dynamic>> messages = [];

  @override
  void initState() {
    super.initState();
    _channel = WebSocketChannel.connect(
      Uri.parse('wss://meetmeapp.duckdns.org/ws/chat/${widget.senderId}'),
    );

    _channel.stream.listen((data) {
      final decoded = jsonDecode(data);
      if ((decoded['sender_id'] == widget.receiverId &&
              decoded['receiver_id'] == widget.senderId) ||
          decoded['sender_id'] == widget.senderId) {
        setState(() => messages.add(decoded));
        _scrollToBottom();
      }
    });

    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final history =
        await ApiService.getChatHistory(widget.senderId, widget.receiverId);
    setState(() => messages = history);
    await Future.delayed(const Duration(milliseconds: 100));
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

    setState(() {
      messages.add(msg);
    });
    _channel.sink.add(jsonEncode(msg));
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
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Chat with ${widget.receiverName}",
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            fontSize: screenWidth * 0.05,
          ),
        ),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: theme.primaryColor),
        centerTitle: false,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.035,
                  vertical: screenWidth * 0.03),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final msg = messages[index];
                final isMe = msg['sender_id'] == widget.senderId;
                final align =
                    isMe ? Alignment.centerRight : Alignment.centerLeft;
                final bubbleColor = isMe
                    ? theme.colorScheme.secondary.withOpacity(0.9)
                    : theme.cardColor.withOpacity(0.95);
                final textColor =
                    isMe ? Colors.white : theme.textTheme.bodyMedium!.color;

                return Align(
                  alignment: align,
                  child: Container(
                    margin: EdgeInsets.symmetric(vertical: screenWidth * 0.015),
                    padding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.04,
                        vertical: screenWidth * 0.03),
                    decoration: BoxDecoration(
                      color: bubbleColor,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      msg['message'],
                      style: TextStyle(
                        fontSize: screenWidth * 0.04,
                        color: textColor,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Divider(height: 1),
          Padding(
            padding: EdgeInsets.fromLTRB(screenWidth * 0.035,
                screenWidth * 0.02, screenWidth * 0.035, screenWidth * 0.03),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    onSubmitted: (_) => _sendMessage(),
                    decoration: InputDecoration(
                      hintText: 'Type your message...',
                      hintStyle: TextStyle(
                        fontFamily: 'Poppins',
                        color: theme.hintColor,
                      ),
                      filled: true,
                      fillColor: theme.cardColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.04,
                          vertical: screenWidth * 0.035),
                    ),
                  ),
                ),
                SizedBox(width: screenWidth * 0.025),
                CircleAvatar(
                  backgroundColor: theme.primaryColor,
                  radius: screenWidth * 0.065,
                  child: IconButton(
                    icon: Icon(Icons.send,
                        color: Colors.white, size: screenWidth * 0.055),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
