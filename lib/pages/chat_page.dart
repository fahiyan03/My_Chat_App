

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
        //BlocConsumer  ->  এটি BlocBuilder এবং BlocListener এর মিশ্রণ। এটি UI ও পরিবর্তন করে আবার error আসলে SnackBar ও দেখায়
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
                    reverse: true,  // reverse: true  -> লিস্টটিকে নিচ থেকে উপরে সাজায়, যা চ্যাট অ্যাপের জন্য আদর্শ (নতুন মেসেজ নিচে থাকে)।
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      return _ChatBubble(message: message);
                    },
                  ),
                ),
                const _MessageBar(),  //_MessageBar ->  স্ক্রিনের নিচে থাকা ইনপুট ফিল্ড এবং সেন্ড বাটন সংবলিত আলাদা একটি অংশ।
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

  void _submitMessage() async {
    final text = _textController.text;
    if (text.isEmpty) return;
    context.read<ChatCubit>().sendMessage(text);  // context.read()  ->  BLoC-এ কোনো ইভেন্ট পাঠানোর (যেমন sendMessage) দ্রুততম মাধ্যম।
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
          bottom: MediaQuery.of(context).padding.bottom,  //MediaQuery ->  ফোনের স্ক্রিনের সাইজ অনুযায়ী প্যাডিং ঠিক করে (বিশেষ করে নচ বা নিচের বার এড়াতে)।
        ),
        child: Row(
          children: [
            Expanded(
              child: TextFormField(
                keyboardType: TextInputType.text,
                maxLines: null,
                autofocus: true,
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

  // Function to show Edit/Delete options
  void _showOptions(BuildContext context) {
    showModalBottomSheet(  //showModalBottomSheet  -> স্ক্রিনের নিচ থেকে একটি ছোট মেনু (Edit/Delete) তুলে আনে।
      context: context,
      builder: (bContext) {
        return SafeArea(   // SafeArea -> ফোনের ক্যামেরা বা নচ এরিয়ায় যাতে কন্টেন্ট ঢুকে না যায় তা নিশ্চিত করে।
          child: Wrap(  // Wrap ->  চাইল্ড উইজেটগুলোকে জায়গামতো সারিবদ্ধ করে রাখে এবং জায়গা না থাকলে পরের লাইনে নিয়ে যায়।
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

  // Function to show the Edit Dialog
  void _showEditDialog(BuildContext context) {
    final editController = TextEditingController(text: message.content);
    showDialog(   //  showDialog ->  স্ক্রিনের মাঝখানে একটি পপআপ বক্স (AlertDialog) দেখায়।
      context: context,
      builder: (dContext) {
        return AlertDialog(
          title: const Text('Edit Message'),
          content: TextField(
            controller: editController,
            autofocus: true,
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
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> chatContents = [
      if (!message.isMine) UserAvatar(userId: message.profileId),
      const SizedBox(width: 12),
      Flexible(                     //  Flexible ->   টেক্সট যদি অনেক বড় হয়, তবে তা স্ক্রিনের বাইরে না গিয়ে নিচের লাইনে চলে আসে।
        child: GestureDetector(    //GestureDetector ->   ইউজারের হাতের স্পর্শ বা ক্লিক ডিটেক্ট করে। এখানে onLongPress এর জন্য ব্যবহৃত হয়েছে।
          onLongPress: message.isMine ? () => _showOptions(context) : null,  //onLongPress  ->  মেসেজের ওপর দীর্ঘক্ষণ চেপে ধরলে এডিট/ডিলিট অপশন দেখানোর ট্রিগার।
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
      //  reversed.toList()  ->    মেসেজের কন্টেন্ট এবং ইউজারের ছবিকে অদলবদল করে (নিজের মেসেজ ডানে, অন্যের মেসেজ বামে)
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


/*

এই ChatPage-এর মাধ্যমে একটি আধুনিক চ্যাট ইন্টারফেস তৈরি করা হয়েছে। এর প্রধান কাজগুলো নিচে দেওয়া হলো:
১. Real-time Messaging: ChatCubit এর মাধ্যমে ডাটাবেসের সাথে কানেক্ট হয়ে এটি প্রতি সেকেন্ডে নতুন মেসেজ চেক করে এবং স্ক্রিন আপডেট করে।
২. Messaging Control: ইউজার নিজের পাঠানো মেসেজের ওপর Long Press (চেপে ধরা) করলে একটি মেনু আসে। সেখান থেকে মেসেজটি ভুল থাকলে Edit করা যায় অথবা একদম Delete করে দেওয়া যায়।
৩. Dynamic UI: message.isMine কন্ডিশন ব্যবহার করে নিজের মেসেজগুলোকে ধূসর (Grey) রঙে ডানপাশে এবং অন্যের মেসেজগুলোকে থিম কালারে বামপাশে দেখানো হয়।
৪. Smart Scrolling: reverse: true ব্যবহারের ফলে নতুন মেসেজ আসা মাত্রই স্ক্রিনটি স্বয়ংক্রিয়ভাবে নিচের দিকে থাকে, যা ইউজারকে স্ক্রল করার ঝামেলা থেকে মুক্তি দেয়।

 */