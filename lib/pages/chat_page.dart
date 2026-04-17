import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_chat_app/components/user_avatar.dart';
import 'package:my_chat_app/cubits/chat/chat_cubit.dart';
import 'package:my_chat_app/models/message.dart';
import 'package:my_chat_app/utils/constants.dart';
import 'package:timeago/timeago.dart';

class ChatPage extends StatelessWidget {
  const ChatPage({Key? key}) : super(key: key);

  static Route<void> route(String roomId) {
    return MaterialPageRoute(
      builder: (context) => BlocProvider<ChatCubit>(
        create: (context) => ChatCubit()..setMessagesListener(roomId),
        child: const ChatPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chat')),
      body: BlocConsumer<ChatCubit, ChatState>(
        listener: (context, state) {
          if (state is ChatError) {
            context.showErrorSnackBar(message: state.message);
          }
        },
        builder: (context, state) {
          if (state is ChatInitial) {
            return preloader;
          } else if (state is ChatLoaded) {
            final messages = state.messages;
            return Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    // Keep reverse: true for the best chat UX (anchors to bottom)
                    reverse: true,
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      return _ChatBubble(message: message);
                    },
                  ),
                ),
                const _MessageBar(),
              ],
            );
          } else if (state is ChatEmpty) {
            return const Column(
              children: [
                Expanded(
                  child: Center(
                    child: Text('Start your conversation now :)'),
                  ),
                ),
                _MessageBar(),
              ],
            );
          } else if (state is ChatError) {
            return Center(child: Text(state.message));
          }
          throw UnimplementedError();
        },
      ),
    );
  }
}

class _MessageBar extends StatefulWidget {
  const _MessageBar({Key? key}) : super(key: key);

  @override
  State<_MessageBar> createState() => _MessageBarState();
}

class _MessageBarState extends State<_MessageBar> {
  late final TextEditingController _textController;

  @override
  void initState() {
    _textController = TextEditingController();
    super.initState();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _submitMessage() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    context.read<ChatCubit>().sendMessage(text);
    _textController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).cardColor,
      child: Padding(
        padding: EdgeInsets.only(
          top: 8,
          left: 8,
          right: 8,
          bottom: MediaQuery.of(context).padding.bottom,
        ),
        child: Row(
          children: [
            Expanded(
              child: TextFormField(
                keyboardType: TextInputType.text,
                maxLines: null,
                autofocus: false,
                controller: _textController,
                decoration: const InputDecoration(
                  hintText: 'Type a message',
                  border: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.all(8),
                ),
              ),
            ),
            TextButton(
              onPressed: _submitMessage,
              child: const Text('Send'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({
    Key? key,
    required this.message,
  }) : super(key: key);

  final Message message;

  void _showOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (bContext) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Edit Message'),
                onTap: () {
                  Navigator.pop(bContext);
                  _showEditDialog(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Delete Message', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(bContext);
                  context.read<ChatCubit>().deleteMessage(message.id);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showEditDialog(BuildContext context) {
    final editController = TextEditingController(text: message.content);
    showDialog(
      context: context,
      builder: (dContext) {
        return AlertDialog(
          title: const Text('Edit Message'),
          content: TextField(
            controller: editController,
            autofocus: true,
            maxLines: null,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dContext),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final newText = editController.text.trim();
                if (newText.isNotEmpty && newText != message.content) {
                  context.read<ChatCubit>().editMessage(message.id, newText);
                }
                Navigator.pop(dContext);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    ).then((_) => editController.dispose()); // Clean up memory after dialog closes
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> chatContents = [
      if (!message.isMine) UserAvatar(userId: message.profileId),
      const SizedBox(width: 12),
      Flexible(
        child: GestureDetector(
          onLongPress: message.isMine ? () => _showOptions(context) : null,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              color: message.isMine
                  ? Colors.grey[300]
                  : Theme.of(context).primaryColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              message.content,
              style: TextStyle(
                color: message.isMine ? Colors.black : Colors.white,
              ),
            ),
          ),
        ),
      ),
      const SizedBox(width: 12),
      Text(format(message.createdAt, locale: 'en_short')),
      const SizedBox(width: 30),
    ];

    if (message.isMine) {
      chatContents = chatContents.reversed.toList();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Row(
        mainAxisAlignment:
        message.isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: chatContents,
      ),
    );
  }
}
