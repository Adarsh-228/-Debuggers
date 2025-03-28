// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:healthcompanion/features/chat/cubit/chat_cubit.dart';
import 'package:healthcompanion/features/chat/data/models/chat_message.dart';
import 'package:url_launcher/url_launcher.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: BlocConsumer<ChatCubit, List<ChatMessage>>(
                listener: (context, state) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _scrollToBottom();
                  });
                },
                builder: (context, messages) {
                  if (messages.isEmpty) {
                    return Center(
                      child: Text(
                        'Start a conversation about nutrition!',
                        style: GoogleFonts.poppins(
                          color: Colors.grey[600],
                          fontSize: 16,
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      return _MessageBubble(message: message);
                    },
                  );
                },
              ),
            ),
            _buildInputBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text(
                      'Clear Chat',
                      style: GoogleFonts.poppins(),
                    ),
                    content: Text(
                      'Are you sure you want to clear the chat history?',
                      style: GoogleFonts.poppins(),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      FilledButton(
                        onPressed: () {
                          context.read<ChatCubit>().clearChat();
                          Navigator.pop(context);
                        },
                        child: const Text('Clear'),
                      ),
                    ],
                  ),
                );
              },
              icon: const Icon(Icons.delete_outline),
            ),
            const SizedBox(width: 2),
            Expanded(
              child: TextField(
                controller: _textController,
                decoration: InputDecoration(
                  hintText: 'Ask about nutrition...',
                  hintStyle: GoogleFonts.poppins(color: Colors.grey),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                ),
                textCapitalization: TextCapitalization.sentences,
                onSubmitted: _sendMessage,
              ),
            ),
            const SizedBox(width: 8),
            Tooltip(
              message: 'Get Grocery List',
              child: IconButton.filled(
                onPressed: () => _sendListMessage(_textController.text),
                icon: const Icon(Icons.list_alt_rounded),
              ),
            ),
            const SizedBox(width: 4),
            Tooltip(
              message: 'Send Message',
              child: IconButton.filled(
                onPressed: () => _sendMessage(_textController.text),
                icon: const Icon(Icons.send_rounded),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;
    context.read<ChatCubit>().sendMessage(text.trim());
    _textController.clear();
  }

  void _sendListMessage(String text) {
    if (text.trim().isEmpty) return;

    String prompt = text;
    context.read<ChatCubit>().sendMessage(prompt, isList: true);
    _textController.clear();
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;

  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        margin: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: message.isUser
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            if (message.type == MessageType.product)
              _buildProductCard(context)
            else if (message.type == MessageType.reference)
              _buildReferences(context)
            else if (message.type == MessageType.list)
              _buildGroceryList(context)
            else
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: _getBubbleColor(context),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  message.content,
                  style: GoogleFonts.poppins(
                    color: message.isUser ? Colors.white : Colors.black87,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _getBubbleColor(BuildContext context) {
    if (message.type == MessageType.error) {
      return Colors.red[100]!;
    }
    return message.isUser
        ? Theme.of(context).colorScheme.primary
        : Colors.grey[200]!;
  }

  Widget _buildProductCard(BuildContext context) {
    final nutrition = message.metadata?['nutrition'];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.metadata?['name'] ?? 'Unknown Product',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            const Divider(),
            _buildNutritionRow('Calories', '${nutrition?['calories']} kcal'),
            _buildNutritionRow('Protein', '${nutrition?['protein']}g'),
            _buildNutritionRow('Carbs', '${nutrition?['carbs']}g'),
            _buildNutritionRow('Fat', '${nutrition?['fat']}g'),
          ],
        ),
      ),
    );
  }

  Widget _buildNutritionRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.poppins()),
          Text(
            value,
            style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildReferences(BuildContext context) {
    final references = message.metadata?['references'] as List?;
    if (references == null || references.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'References',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            const Divider(),
            ...references.map((ref) => InkWell(
                  onTap: () => launchUrl(Uri.parse(ref['url'])),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.link, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            ref['title'] ?? 'Reference',
                            style: GoogleFonts.poppins(
                              color: Colors.blue,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildGroceryList(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Weekly Grocery List',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
            const Divider(),
            ..._parseListContent(message.content),
          ],
        ),
      ),
    );
  }

  List<Widget> _parseListContent(String content) {
    final cleanedContent = content
        .replaceAll('**', '') // Remove any bold markers
        .replaceAll('__', '') // Remove any underline markers
        .replaceAll(RegExp(r'\*{1,3}'), ''); // Remove any remaining asterisks

    return cleanedContent.split('\n').map((line) {
      final categoryMatch = RegExp(r'^\[(.*?)\]$').firstMatch(line.trim());
      if (categoryMatch != null) {
        return Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            categoryMatch.group(1)!,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w500,
              fontSize: 16,
            ),
          ),
        );
      }

      if (line.trim().startsWith('- [ ]')) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.check_box_outline_blank, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  line.replaceAll('- [ ]', '').trim(),
                  style: GoogleFonts.poppins(fontSize: 14),
                ),
              ),
              if (line.contains('❄️'))
                const Padding(
                  padding: EdgeInsets.only(left: 4),
                  child: Icon(Icons.ac_unit, size: 14),
                ),
            ],
          ),
        );
      }

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Text(
          line.trim(),
          style: GoogleFonts.poppins(fontSize: 14),
        ),
      );
    }).toList();
  }
}
