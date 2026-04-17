// import 'dart:async';
//
// import 'package:bloc/bloc.dart';
// import 'package:meta/meta.dart';
// import 'package:my_chat_app/models/message.dart';
// import 'package:my_chat_app/utils/constants.dart';
//
// part 'chat_state.dart';
//
// class ChatCubit extends Cubit<ChatState> {
//   ChatCubit() : super(ChatInitial());
//
//   StreamSubscription<List<Message>>? _messagesSubscription;
//   List<Message> _messages = [];
//
//   late final String _roomId;
//   late final String _myUserId;
//
//   void setMessagesListener(String roomId) {
//     _roomId = roomId;
//
//     _myUserId = supabase.auth.currentUser!.id;
//
//     _messagesSubscription = supabase
//         .from('messages')
//         .stream(primaryKey: ['id'])
//         .eq('room_id', roomId)
//         .order('created_at')
//         .map<List<Message>>(
//           (data) => data
//               .map<Message>(
//                   (row) => Message.fromMap(map: row, myUserId: _myUserId))
//               .toList(),
//         )
//         .listen((messages) {
//           _messages = messages;
//           if (_messages.isEmpty) {
//             emit(ChatEmpty());
//           } else {
//             emit(ChatLoaded(_messages));
//           }
//         });
//   }
//
//   Future<void> sendMessage(String text) async {
//     /// Add message to present to the user right away
//     final message = Message(
//       id: 'new',
//       roomId: _roomId,
//       profileId: _myUserId,
//       content: text,
//       createdAt: DateTime.now(),
//       isMine: true,
//     );
//     _messages.insert(0, message);
//     emit(ChatLoaded(_messages));
//
//     try {
//       await supabase.from('messages').insert(message.toMap());
//     } catch (_) {
//       emit(ChatError('Error submitting message.'));
//       _messages.removeWhere((message) => message.id == 'new');
//       emit(ChatLoaded(_messages));
//     }
//   }
//
//   @override
//   Future<void> close() {
//     _messagesSubscription?.cancel();
//     return super.close();
//   }
// }



import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'package:my_chat_app/models/message.dart';
import 'package:my_chat_app/utils/constants.dart';

part 'chat_state.dart';

class ChatCubit extends Cubit<ChatState> {
  ChatCubit() : super(ChatInitial());

  StreamSubscription<List<Message>>? _messagesSubscription;
  List<Message> _messages = [];

  late final String _roomId;
  late final String _myUserId;

  void setMessagesListener(String roomId) {
    _roomId = roomId;

    _myUserId = supabase.auth.currentUser!.id;

    _messagesSubscription = supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('room_id', roomId)
        .order('created_at')
        .map<List<Message>>(
          (data) => data
          .map<Message>(
              (row) => Message.fromMap(map: row, myUserId: _myUserId))
          .toList(),
    )
        .listen((messages) {
      _messages = messages;
      if (_messages.isEmpty) {
        emit(ChatEmpty());
      } else {
        emit(ChatLoaded(_messages));
      }
    });
  }

  Future<void> sendMessage(String text) async {
    final message = Message(
      id: 'new',
      roomId: _roomId,
      profileId: _myUserId,
      content: text,
      createdAt: DateTime.now(),
      isMine: true,
    );
    _messages.insert(0, message);
    emit(ChatLoaded(_messages));

    try {
      await supabase.from('messages').insert(message.toMap());
    } catch (_) {
      emit(ChatError('Error submitting message.'));
      _messages.removeWhere((message) => message.id == 'new');
      emit(ChatLoaded(_messages));
    }
  }

  /// নতুন মেথড: মেসেজ এডিট করার জন্য
  Future<void> editMessage(String messageId, String newContent) async {
    try {
      await supabase.from('messages').update({
        'content': newContent,
      }).match({'id': messageId});
    } catch (error) {
      emit(ChatError('Failed to edit message.'));
      emit(ChatLoaded(_messages));
    }
  }

  /// নতুন মেথড: মেসেজ ডিলিট করার জন্য
  Future<void> deleteMessage(String messageId) async {
    try {
      await supabase.from('messages').delete().match({'id': messageId});
    } catch (error) {
      emit(ChatError('Failed to delete message.'));
      emit(ChatLoaded(_messages));
    }
  }

  @override
  Future<void> close() {
    _messagesSubscription?.cancel();
    return super.close();
  }
}