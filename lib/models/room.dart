import 'package:my_chat_app/models/message.dart';

class Room {  //একটি "রুম" বা চ্যাট সেশনের ব্লু-প্রিন্ট তৈরি করে।
  Room({
    required this.id,  //প্রতিটি চ্যাট রুমের ইউনিক আইডি যা ডাটাবেসে রুমটিকে শনাক্ত করে।
    required this.createdAt,
    required this.otherUserId,
    this.lastMessage,
  });

  /// ID of the room
  final String id;

  /// Date and time when the room was created
  final DateTime createdAt;  //রুমটি কখন তৈরি হয়েছে তার সঠিক সময় এবং তারিখ ধারণ করে।

  /// ID of the user who the user is talking to
  final String otherUserId;  //আপনি কার সাথে কথা বলছেন তার প্রোফাইল আইডি।

  /// Latest message submitted in the room
  final Message? lastMessage;  //Message? -> রুমের সর্বশেষ মেসেজটি। ? চিহ্নটির মানে হলো কোনো মেসেজ না থাকলেও (নতুন রুম) কোডটি ক্রাশ করবে না।

  Map<String, dynamic> toMap() {  //toMap()  ->  অ্যাপের অবজেক্টকে JSON বা ম্যাপ ফরমেটে রূপান্তর করে যাতে তা ডাটাবেসে পাঠানো যায়।
    return {
      'id': id,
      'createdAt': createdAt.millisecondsSinceEpoch,  //তারিখকে একটি সংখ্যায় রূপান্তর করে (যেমন: ১৭০৪১২৩৪৫৬), যা ডাটাবেসে সেভ করা সহজ।
    };
  }

  /// Creates a room object from room_participants table
  Room.fromRoomParticipants(Map<String, dynamic> map)
  //fromRoomParticipants -> ডাটাবেসের room_participants টেবিল থেকে আসা ডাটাকে Room অবজেক্টে রূপান্তর করে।
      : id = map['room_id'],
        otherUserId = map['profile_id'],
        createdAt = DateTime.parse(map['created_at']),
  //DateTime.parse -> ডাটাবেসের টেক্সট ফরম্যাটের তারিখকে (2024-01-01...) Flutter-এর পড়ার যোগ্য তারিখ অবজেক্টে রূপান্তর করে।
        lastMessage = null;

  Room copyWith({  //copyWith -> বর্তমান রুমের সব তথ্য ঠিক রেখে শুধু একটি নির্দিষ্ট তথ্য (যেমন: lastMessage) আপডেট করে নতুন অবজেক্ট তৈরি করে।
    String? id,
    DateTime? createdAt,
    String? otherUserId,
    Message? lastMessage,
  }) {
    return Room(
      id: id ?? this.id,  //?? ->  যদি নতুন কোনো ভ্যালু না দেওয়া হয়, তবে আগের ভ্যালুটিই বহাল রাখে।
      createdAt: createdAt ?? this.createdAt,
      otherUserId: otherUserId ?? this.otherUserId,
      lastMessage: lastMessage ?? this.lastMessage,
    );
  }
}


/*

এই Room Model ফাইলটি আপনার অ্যাপের ডাটা স্ট্রাকচার নির্ধারণ করে। এর মূল কাজগুলো হলো:
১. Data Mapping: ডাটাবেসের অগোছালো তথ্যকে Room.id বা Room.otherUserId এর মতো সহজ নামে সাজিয়ে দেয়।
২. Last Message Tracking: প্রতিটি চ্যাট রুমের ভেতরে সবশেষ মেসেজটি কী ছিল, তা এই মডেলের মাধ্যমে অ্যাপ জানতে পারে, যা ইনবক্স স্ক্রিনে দেখানো হয়।
৩. State Management Support: copyWith মেথডটি ব্যবহারের ফলে রিয়েল-টাইমে যখন নতুন মেসেজ আসে, তখন পুরো পেজ রিফ্রেশ না করে শুধু ওই নির্দিষ্ট রুমের তথ্য আপডেট করা সম্ভব হয়।
৪. Timestamps: এটি রুম তৈরির সময় এবং তারিখ নির্ভুলভাবে সংরক্ষণ করে যাতে চ্যাট লিস্টটি সময়ের ক্রমানুসারে সাজানো যায়।
 */