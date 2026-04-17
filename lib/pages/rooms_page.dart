import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_chat_app/cubits/profiles/profiles_cubit.dart';

import 'package:my_chat_app/cubits/rooms/rooms_cubit.dart';
import 'package:my_chat_app/models/profile.dart';
import 'package:my_chat_app/pages/chat_page.dart';
import 'package:my_chat_app/pages/register_page.dart';
import 'package:my_chat_app/utils/constants.dart';
import 'package:timeago/timeago.dart';

/// Displays the list of chat threads
class RoomsPage extends StatelessWidget {
  const RoomsPage({Key? key}) : super(key: key);

  static Route<void> route() {
    return MaterialPageRoute(
      builder: (context) => BlocProvider<RoomCubit>(
        // BlocProvider ->   RoomCubit কে এই পেজের জন্য তৈরি করে এবং নিচের সব উইজেটের কাছে ডাটা পৌঁছে দেয়।

        create: (context) => RoomCubit()..initializeRooms(context),  //initializeRooms -> অবজেক্ট তৈরি করার সাথে সাথেই একটি ফাংশন কল করে ডাটা লোড করা শুরু করে।
        child: const RoomsPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rooms'),
        actions: [
          TextButton(
            onPressed: () async {
              await supabase.auth.signOut();  //signOut  ->  ইউজারের বর্তমান সেশনটি শেষ করে দেয় এবং লগআউট করে।
              Navigator.of(context).pushAndRemoveUntil(
                RegisterPage.route(),
                (route) => false,
              );
            },
            child: const Text('Logout'),
          ),
        ],
      ),
      body: BlocBuilder<RoomCubit, RoomState>(  //BlocBuilder  -> স্টেট (যেমন: Loading, Loaded, Error) পরিবর্তনের সাথে সাথে স্ক্রিন অটোমেটিক আপডেট করে।
        builder: (context, state) {
          if (state is RoomsLoading) {  //state is RoomsLoading ->  বর্তমান ডাটাগুলো সফলভাবে সার্ভার থেকে এসেছে কি না তা নিশ্চিত করে।
            return preloader;
          } else if (state is RoomsLoaded) {
            final newUsers = state.newUsers;
            final rooms = state.rooms;
            return BlocBuilder<ProfilesCubit, ProfilesState>(
              builder: (context, state) {
                if (state is ProfilesLoaded) {
                  final profiles = state.profiles;
                  return Column(
                    children: [
                      _NewUsers(newUsers: newUsers),
                      Expanded(
                        child: ListView.builder(   //ListView.builder -> অনেকগুলো চ্যাট রুম থাকলে সেগুলো মেমোরি বাঁচিয়ে দক্ষতার সাথে স্ক্রিনে দেখায়।
                          itemCount: rooms.length,
                          itemBuilder: (context, index) {
                            final room = rooms[index];
                            final otherUser = profiles[room.otherUserId];

                            return ListTile(  //ListTile ->  প্রতিটি চ্যাট রো (Row) তৈরি করে যেখানে প্রোফাইল পিক, নাম এবং মেসেজ থাকে।
                              onTap: () => Navigator.of(context)
                                  .push(ChatPage.route(room.id)),
                              leading: CircleAvatar(  // CircleAvatar -> ইউজারের নামের প্রথম দুই অক্ষর দিয়ে গোল একটি প্রোফাইল আইকন তৈরি করে।
                                child: otherUser == null
                                    ? preloader
                                    : Text(otherUser.username.substring(0, 2)),
                              ),
                              title: Text(otherUser == null
                                  ? 'Loading...'
                                  : otherUser.username),
                              subtitle: room.lastMessage != null
                                  ? Text(
                                      room.lastMessage!.content,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,  //overflow ->মেসেজ খুব লম্বা হলে সেটি কেটে দিয়ে শেষে তিনটি ডট (...) দেখায়।
                                    )
                                  : const Text('Room created'),
                              trailing: Text(format(  // format ->  তারিখকে সহজ ভাষায় (যেমন: 5m ago, 2h ago) রূপান্তর করে।
                                  room.lastMessage?.createdAt ?? room.createdAt,
                                  locale: 'en_short')),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                } else {
                  return preloader;
                }
              },
            );
          } else if (state is RoomsEmpty) {
            final newUsers = state.newUsers;
            return Column(
              children: [
                _NewUsers(newUsers: newUsers),
                const Expanded(
                  child: Center(
                    child: Text('Start a chat by tapping on available users'),
                  ),
                ),
              ],
            );
          } else if (state is RoomsError) {
            return Center(child: Text(state.message));
          }
          throw UnimplementedError();
        },
      ),
    );
  }
}

class _NewUsers extends StatelessWidget {
  const _NewUsers({
    Key? key,
    required this.newUsers,
  }) : super(key: key);

  final List<Profile> newUsers;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(  //SingleChildScrollView -> নতুন ইউজারদের লিস্টটি বাম থেকে ডানে (Horizontal) স্ক্রল করার সুবিধা দেয়।
      padding: const EdgeInsets.symmetric(vertical: 8),
      scrollDirection: Axis.horizontal,
      child: Row(
        children: newUsers
            .map<Widget>((user) => InkWell(  //InkWell -> ছবির ওপর ক্লিক করলে একটি ঢেউয়ের মতো ইফেক্ট (Ripple) দেয় এবং ফাংশন ট্রিগার করে।
        onTap: () async {
                    try {
                      final roomId = await BlocProvider.of<RoomCubit>(context)
                          .createRoom(user.id);  //createRoom->  নতুন কোনো ইউজারের ওপর ক্লিক করলে তাদের সাথে একটি চ্যাট রুম তৈরি করে।
                      Navigator.of(context).push(ChatPage.route(roomId));
                    } catch (_) {
                      context.showErrorSnackBar(
                          message: 'Failed creating a new room');
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: SizedBox(
                      width: 60,
                      child: Column(
                        children: [
                          CircleAvatar(
                            child: Text(user.username.substring(0, 2)),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            user.username,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                ))
            .toList(),
      ),
    );
  }
}


/*
এই RoomsPage ফাইলটি আপনার চ্যাট অ্যাপের মূল ড্যাশবোর্ড হিসেবে কাজ করে। এর প্রধান ফিচারগুলো হলো:
১. Chat List: এটি বর্তমান ইউজারের সব পুরনো চ্যাট রুমগুলো লিস্ট আকারে দেখায়। প্রতিটি চ্যাটে শেষ মেসেজটি কী ছিল এবং কখন পাঠানো হয়েছিল তা দেখা যায়।
২. New Users Discovery: স্ক্রিনের উপরের দিকে নতুন ইউজারদের প্রোফাইল দেখা যায়। তাদের ওপর ক্লিক করলে ডাটাবেসে একটি নতুন চ্যাট রুম তৈরি হয় এবং আপনি সরাসরি চ্যাট পেজে চলে যান।
৩. State Management: এখানে RoomCubit এবং ProfilesCubit একসাথে কাজ করছে। একটি মেসেজ এবং রুমের তথ্য দিচ্ছে, অন্যটি সেই রুমের ইউজারের প্রোফাইল তথ্য দিচ্ছে।
৪. Authentication Control: উপরে একটি 'Logout' বাটন আছে যা ইউজারকে লগআউট করিয়ে আবার রেজিস্ট্রেশন পেজে পাঠিয়ে দেয়।
 */