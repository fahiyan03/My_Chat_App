import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_chat_app/cubits/profiles/profiles_cubit.dart';
import 'package:my_chat_app/models/profile.dart';
import 'package:my_chat_app/models/message.dart';
import 'package:my_chat_app/models/room.dart';
import 'package:my_chat_app/utils/constants.dart';

part 'rooms_state.dart';

class RoomCubit extends Cubit<RoomState> {
  RoomCubit() : super(RoomsLoading());

  final Map<String, StreamSubscription<Message?>> _messageSubscriptions = {};
  //Map<String, ...>    -> প্রতিটি রুমের জন্য আলাদা আলাদা মেসেজ লিসেনার ট্র্যাক করে রাখে যাতে ডাটা উলটপালট না হয়।

  late final String _myUserId;

  /// List of new users of the app for the user to start talking to
  late final List<Profile> _newUsers;

  /// List of rooms
  List<Room> _rooms = [];
  StreamSubscription<List<Map<String, dynamic>>>? _rawRoomsSubscription;
  bool _haveCalledGetRooms = false;

  Future<void> initializeRooms(BuildContext context) async {
    //initializeRooms -> অ্যাপ ওপেন করার পর প্রথমবার নতুন ইউজার এবং চ্যাট রুমগুলো লোড করার দায়িত্ব পালন করে।
    if (_haveCalledGetRooms) {
      return;
    }
    _haveCalledGetRooms = true;  //একই ডাটা যেন বারবার রিকোয়েস্ট না হয় (Duplicate call) তা নিশ্চিত করার জন্য একটি নিরাপত্তা লক।

    _myUserId = supabase.auth.currentUser!.id;

    late final List data;

    try {
      data = await supabase
          .from('profiles')
          .select()
          .not('id', 'eq', _myUserId)  //প্রোফাইল লিস্ট থেকে আপনার নিজের প্রোফাইলটি বাদ দিয়ে বাকিদের খুঁজে বের করার শর্ত।
          .order('created_at')
          .limit(12);  //শুরুতে অনেক বেশি ডাটা লোড না করে শুধুমাত্র ১২ জন নতুন ইউজারের প্রোফাইল নিয়ে আসে।
    } catch (_) {
      emit(RoomsError('Error loading new users'));
    }

    final rows = List<Map<String, dynamic>>.from(data);
    _newUsers = rows.map(Profile.fromMap).toList();

    /// Get realtime updates on rooms that the user is in
    _rawRoomsSubscription = supabase.from('room_participants').stream(  //room_participants -> ডাটাবেসের সেই টেবিল যেখানে লেখা থাকে কোন ইউজার কোন কোন চ্যাট রুমের সদস্য।
      primaryKey: ['room_id', 'profile_id'],
    ).listen((participantMaps) async {
      if (participantMaps.isEmpty) {
        emit(RoomsEmpty(newUsers: _newUsers));
        return;
      }

      _rooms = participantMaps
          .map(Room.fromRoomParticipants)
          .where((room) => room.otherUserId != _myUserId)  //রুম লিস্ট থেকে শুধুমাত্র সেই তথ্যগুলো রাখে যেখানে আপনার সাথে অন্য কোনো ইউজার যুক্ত আছে।
          .toList();
      for (final room in _rooms) {
        _getNewestMessage(context: context, roomId: room.id);
        //_getNewestMessage  -> প্রতিটি রুমের সর্বশেষ মেসেজটি কী ছিল তা রিয়েল-টাইমে মনিটর করার জন্য লিসেনার তৈরি করে।

        BlocProvider.of<ProfilesCubit>(context).getProfile(room.otherUserId);
      }
      emit(RoomsLoaded(
        newUsers: _newUsers,
        rooms: _rooms,
      ));
    }, onError: (error) {
      emit(RoomsError('Error loading rooms'));
    });
  }

  // Setup listeners to listen to the most recent message in each room
  void _getNewestMessage({
    required BuildContext context,
    required String roomId,
  }) {
    _messageSubscriptions[roomId] = supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('room_id', roomId)
        .order('created_at')
        .limit(1)
        .map<Message?>(
          (data) => data.isEmpty
              ? null
              : Message.fromMap(
                  map: data.first,
                  myUserId: _myUserId,
                ),
        )
        .listen((message) {
          final index = _rooms.indexWhere((room) => room.id == roomId);  //indexWhere -> আপডেট হওয়া রুমটি আপনার বর্তমান লিস্টের কত নম্বর পজিশনে আছে তা খুঁজে বের করে।
          _rooms[index] = _rooms[index].copyWith(lastMessage: message);  //copyWith -> পুরনো রুম অবজেক্টের সব তথ্য ঠিক রেখে শুধু নতুন মেসেজটি (Last Message) আপডেট করে একটি নতুন অবজেক্ট বানায়।
          _rooms.sort((a, b) {  //sort ->  যার মেসেজ আগে এসেছে তাকে নিচে এবং নতুন মেসেজ ওয়ালা রুমকে সবার উপরে নিয়ে আসে।
            /// Sort according to the last message
            /// Use the room createdAt when last message is not available
            final aTimeStamp =
                a.lastMessage != null ? a.lastMessage!.createdAt : a.createdAt;
            final bTimeStamp =
                b.lastMessage != null ? b.lastMessage!.createdAt : b.createdAt;
            return bTimeStamp.compareTo(aTimeStamp);
          });
          if (!isClosed) {  //isClosed ->  স্টেট পরিবর্তন করার আগে চেক করে যে ইউজার স্ক্রিনটি বন্ধ করে চলে গেছে কি না; যা ক্রাশ হওয়া আটকায়।
            emit(RoomsLoaded(
              newUsers: _newUsers,
              rooms: _rooms,
            ));
          }
        });
  }

  /// Creates or returns an existing roomID of both participants
  Future<String> createRoom(String otherUserId) async {
    final data = await supabase
        .rpc('create_new_room', params: {'other_user_id': otherUserId});  //rpc ->  ডাটাবেসের ভেতরে তৈরি করা একটি কাস্টম ফাংশন (Database Function) কল করে নতুন রুম তৈরি করে।
    emit(RoomsLoaded(rooms: _rooms, newUsers: _newUsers));
    return data as String;
  }

  @override
  Future<void> close() {
    _rawRoomsSubscription?.cancel();
    return super.close();
  }
}
/*

এই RoomCubit ফাইলটি আপনার ইনবক্স বা রুম ম্যানেজমেন্টের প্রাণ। এর কাজগুলো হলো:
১. Discovery: এটি ডাটাবেস থেকে ১২ জন নতুন ইউজারের প্রোফাইল নিয়ে আসে যাতে আপনি তাদের সাথে চ্যাট শুরু করতে পারেন।
২. Active Rooms Tracking: আপনি কতগুলো রুমে চ্যাট করছেন তার একটি লিস্ট তৈরি করে। সুপাবেসের stream ব্যবহারের ফলে যদি কেউ আপনাকে নতুন মেসেজ দেয় বা নতুন কোনো রুমে যুক্ত করে, তবে পেজ রিফ্রেশ ছাড়াই তা ইনবক্সে চলে আসে।
৩. Sorting & Last Message: এটি প্রতিটি চ্যাট রুমের ভেতর ঢুকে সবশেষ মেসেজটি খুঁজে আনে এবং তার ওপর ভিত্তি করে রুমগুলোকে সাজায়। অর্থাৎ, যে রুমে আপনি সবশেষ মেসেজ পেয়েছেন বা দিয়েছেন, সেটি অটোমেটিক সবার উপরে চলে আসে।
৪. Smart Navigation: createRoom মেথডটি ব্যবহার করে যখন আপনি নতুন কোনো ইউজারের ওপর ক্লিক করেন, এটি ডাটাবেসে একটি নতুন রুম আইডি তৈরি করে দেয় যাতে আপনি চ্যাট শুরু করতে পারেন।

 */