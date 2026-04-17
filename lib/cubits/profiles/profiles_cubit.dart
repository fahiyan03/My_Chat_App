import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'package:my_chat_app/models/profile.dart';
import 'package:my_chat_app/utils/constants.dart';

part 'profiles_state.dart';

class ProfilesCubit extends Cubit<ProfilesState> {  //  প্রোফাইল ডাটা লোড করা এবং মেমোরিতে ক্যাশ (Cache) করে রাখার লজিক নিয়ন্ত্রণ করে।
  ProfilesCubit() : super(ProfilesInitial());   // ProfilesInitial ->   যখন অ্যাপটি প্রথম চালু হয় এবং কোনো প্রোফাইল এখনো লোড হয়নি, তখনকার অবস্থা।

  /// Map of app users cache in memory with profile_id as the key
  final Map<String, Profile?> _profiles = {};

  Future<void> getProfile(String userId) async {   //  getProfile  ->   নির্দিষ্ট কোনো ইউজারের আইডি দিয়ে তার নাম বা ছবি ডাটাবেস থেকে খুঁজে আনে।
    if (_profiles[userId] != null) {   // চেক করে যে এই ইউজারের তথ্য কি আগে থেকেই মেমোরিতে আছে? থাকলে আর ডাটাবেসে যায় না।
      return;   // যদি তথ্য ক্যাশ-এ থাকে, তবে ফাংশনটি এখানেই শেষ হয়ে যায়, যা ইন্টারনেটের খরচ বাঁচায়।
    }

    final data =
        await supabase.from('profiles').select().match({'id': userId}).single();  //select -> প্রোফাইল টেবিলের সব কলামের ডাটা নিয়ে আসার কমান্ড।
        // match({'id': userId})  ->  শুধুমাত্র ওই নির্দিষ্ট আইডির ইউজারের তথ্যটিই খুঁজে বের করে।
    if (data == null) {
      return;
    }
    _profiles[userId] = Profile.fromMap(data);

    emit(ProfilesLoaded(profiles: _profiles));
  }
}


/*

এই ProfilesCubit ফাইলটি আপনার অ্যাপের পারফরম্যান্স বাড়ানোর জন্য অত্যন্ত গুরুত্বপূর্ণ। এর কাজগুলো হলো:
১. On-Demand Loading: যখনই চ্যাট লিস্টে কোনো নতুন ইউজারের আইডি পাওয়া যায়, এটি তখন তাদের প্রোফাইল (নাম, ছবি) সার্ভার থেকে নিয়ে আসে।
২. Memory Caching: এটি একই ইউজারের তথ্য বারবার ডাউনলোড করে না। একবার ডাউনলোড করলে তা _profiles ম্যাপে জমা রাখে। এর ফলে অ্যাপটি অনেক দ্রুত কাজ করে এবং ডাটাবেসের ওপর চাপ কম পড়ে।
৩. Data Synchronization: যখনই কোনো নতুন প্রোফাইল লোড হয়, এটি ProfilesLoaded স্টেটটি ইমিট (Emit) করে, যার ফলে স্ক্রিনে থাকা "Loading..." লেখাটি বদলে ইউজারের নাম চলে আসে।

 */