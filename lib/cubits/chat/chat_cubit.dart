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

  late String _roomId;
  late String _myUserId;

  void setMessagesListener(String roomId) {
    _messagesSubscription?.cancel();

    _roomId = roomId;
    _myUserId = supabase.auth.currentUser!.id;

    _messagesSubscription = supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('room_id', roomId)
        .order('created_at', ascending: false)
        .map<List<Message>>(
          (data) => data
          .map<Message>(
            (row) => Message.fromMap(map: row, myUserId: _myUserId),
      )
          .toList(),
    )
        .listen(
          (messages) {
        // 🔥 THE TRUTH LOG: Look at this on the RECIPIENT'S console
        print("DEBUG: Stream updated. Count: ${messages.length}. IDs: ${messages.map((m) => m.id).toList()}");

        _messages = List.from(messages);

        if (_messages.isEmpty) {
          emit(ChatEmpty());
        } else {
          emit(ChatLoaded(List.from(_messages)));
        }
      },
      onError: (error) {
        print("DEBUG: Stream Error: $error");
        emit(ChatError('Realtime connection error: $error'));
      },
    );
  }

  Future<void> sendMessage(String text) async {
    final tempId = DateTime.now().millisecondsSinceEpoch.toString();
    final message = Message(
      id: tempId,
      roomId: _roomId,
      profileId: _myUserId,
      content: text,
      createdAt: DateTime.now(),
      isMine: true,
    );

    _messages.insert(0, message);
    emit(ChatLoaded(List.from(_messages)));

    try {
      await supabase.from('messages').insert(message.toMap());
    } catch (e) {
      print("DEBUG: Send Error: $e");
      _messages.removeWhere((m) => m.id == tempId);
      emit(ChatLoaded(List.from(_messages)));
      emit(ChatError('Error submitting message.'));
    }
  }

  Future<void> editMessage(String messageId, String newContent) async {
    final index = _messages.indexWhere((m) => m.id == messageId);
    if (index == -1) return;
    final oldMessage = _messages[index];

    _messages[index] = oldMessage.copyWith(content: newContent);
    emit(ChatLoaded(List.from(_messages)));

    try {
      await supabase.from('messages').update({'content': newContent}).eq('id', messageId);
    } catch (e) {
      print("DEBUG: Edit Error: $e");
      _messages[index] = oldMessage;
      emit(ChatLoaded(List.from(_messages)));
      emit(ChatError('Failed to edit message.'));
    }
  }

  Future<void> deleteMessage(String messageId) async {
    final backup = List<Message>.from(_messages);
    _messages.removeWhere((m) => m.id == messageId);
    emit(ChatLoaded(List.from(_messages)));

    try {
      await supabase.from('messages').delete().eq('id', messageId);
    } catch (e) {
      print("DEBUG: Delete Error: $e");
      _messages = backup;
      emit(ChatLoaded(List.from(_messages)));
      emit(ChatError('Failed to delete message.'));
    }
  }

  @override
  Future<void> close() {
    _messagesSubscription?.cancel();
    return super.close();
  }
}
