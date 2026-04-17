part of 'rooms_cubit.dart';  //part of  -> এটি নির্দেশ করে যে এই ফাইলটি rooms_cubit.dart-এর একটি অবিচ্ছেদ্য অংশ।

@immutable   //নিশ্চিত করে যে একবার স্টেট তৈরি হয়ে গেলে তার ভেতরের ডাটা আর সরাসরি পরিবর্তন করা যাবে না।
abstract class RoomState {}  //এটি একটি ব্লু-প্রিন্ট; অন্য সব স্টেট (Loading, Loaded) একে ভিত্তি করে তৈরি হয়

class RoomsLoading extends RoomState {}  //RoomsLoading ->  যখন অ্যাপটি সার্ভার থেকে রুম লিস্ট এবং নতুন ইউজারদের তথ্য খুঁজছে, তখন এটি ব্যবহৃত হয়।

class RoomsLoaded extends RoomState {  //RoomsLoaded  -> ডাটা সফলভাবে পাওয়ার পর এই স্টেটটি newUsers এবং rooms লিস্ট দুটোই একসাথে বহন করে।
  final List<Profile> newUsers;
  final List<Room> rooms;  //final List<Room>   -> এটি ইউজারের বর্তমানে চালু থাকা সব চ্যাট রুমের একটি তালিকা ধরে রাখে।

  RoomsLoaded({
    required this.rooms,  //required  ->  এটি নিশ্চিত করে যে RoomsLoaded স্টেট তৈরি করার সময় অবশ্যই ডাটাগুলো প্রদান করতে হবে।
    required this.newUsers,
  });
}

class RoomsEmpty extends RoomState {  //RoomsEmpty ->  যদি ইউজারের কোনো চ্যাট হিস্ট্রি না থাকে, তবুও নতুন ইউজারদের লিস্ট দেখানোর জন্য এটি ব্যবহৃত হয়।
  final List<Profile> newUsers;

  RoomsEmpty({required this.newUsers});
}

class RoomsError extends RoomState {  //RoomsError ->  ডাটা লোডিং ব্যর্থ হলে (যেমন: ইন্টারনেট না থাকলে) এটি এরর মেসেজটি স্ক্রিনে পৌঁছে দেয়।
  final String message;

  RoomsError(this.message);
}


/*
এই RoomsState ফাইলটি ইনবক্স স্ক্রিনের ৪টি প্রধান পরিস্থিতি বা মোড নিয়ন্ত্রণ করে:
১. লোডিং অবস্থা (RoomsLoading): অ্যাপটি ওপেন করার পর যতক্ষণ ডাটা না আসছে, ততক্ষণ এটি স্ক্রিনে একটি প্রিলোডার বা বাফার দেখানোর সংকেত দেয়।
২. সাফল্য বা ডাটা প্রাপ্তি (RoomsLoaded): এটি সবচেয়ে গুরুত্বপূর্ণ স্টেট। এটি যখন একটিভ হয়, তখন ইউজার তার চ্যাট রুমগুলো এবং নতুন ইউজারদের প্রোফাইল ছবি স্ক্রিনে দেখতে পান।
৩. ফাঁকা ইনবক্স (RoomsEmpty): যদি আপনি আগে কারো সাথে কথা না বলে থাকেন, তবে আপনার ইনবক্স খালি দেখাবে। কিন্তু এই স্টেটটি বুদ্ধিমানের মতো কাজ করে—এটি ইনবক্স খালি দেখালেও আপনাকে "নতুন ইউজারদের" তালিকা দেখায় যাতে আপনি চ্যাট শুরু করতে পারেন।
৪. ব্যর্থতা (RoomsError): সার্ভারের সাথে যোগাযোগ বিচ্ছিন্ন হলে এটি ব্যবহারকারীকে একটি সতর্কবার্তা দেখায়।

 */