

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_chat_app/cubits/profiles/profiles_cubit.dart';
import 'package:my_chat_app/utils/constants.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:my_chat_app/pages/splash_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();  //WidgetsFlutterBinding -> Flutter ইঞ্জিন এবং ফ্রেমওয়ার্কের মধ্যে যোগাযোগ স্থাপন করে।
  // ensureInitialized-> নিশ্চিত করে যে অ্যাপ শুরু হওয়ার আগে সব প্লাগইন সঠিকভাবে সেটআপ হয়েছে।

  await Supabase.initialize(
    // TODO: Replace credentials with your own
    url: 'https://mcegiuugyebqpduejliy.supabase.co',
    anonKey: 'sb_publishable_tqpZFekglwYYzZHOsrVwgg_Ee9nSb4f',
      realtimeClientOptions: const RealtimeClientOptions(
        eventsPerSecond: 10,),

  );

  runApp(const MyApp());  //runApp-> আপনার তৈরি করা UI (Widget) স্ক্রিনে দেখানো শুরু করে।
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ProfilesCubit>(    //BlocProvider -> পুরো অ্যাপে বা নির্দিষ্ট অংশে Data (State) ম্যানেজ করার জন্য ProfilesCubit কে এভেইলঅ্যাবল করে।
      create: (context) => ProfilesCubit(),
      child: MaterialApp(    //MaterialApp -> অ্যাপের ডিজাইন থিম, টাইটেল এবং নেভিগেশন কন্ট্রোল করে।
        title: 'SupaChat',
        debugShowCheckedModeBanner: false,
        theme: appTheme,
        home: const SplashPage(),   //home -> অ্যাপ ওপেন হওয়ার পর প্রথম কোন পেজটি (এখানে SplashPage) দেখাবে তা ঠিক করে।
      ),
    );
  }
}


/*
এই কোডটি মূলত একটি চ্যাট অ্যাপ্লিকেশনের Initialization বা শুরুর ধাপ। এখানে তিনটি প্রধান কাজ করা হয়েছে:
    Backend Connection: Supabase.initialize ব্যবহার করে অ্যাপটিকে একটি অনলাইন ডাটাবেসের সাথে যুক্ত করা হয়েছে যাতে ইউজারদের চ্যাট এবং প্রোফাইল ডাটা সেভ করা যায়।
    State Management: BlocProvider এর মাধ্যমে ProfilesCubit যুক্ত করা হয়েছে, যা ব্যবহারকারীর প্রোফাইল সংক্রান্ত তথ্য (যেমন নাম বা ছবি) পুরো অ্যাপে ম্যানেজ করবে।
    App Startup: অ্যাপটি চালু হওয়ার পর প্রথম SplashPage দেখাবে, যা সাধারণত লোডিং বা লোগো দেখানোর জন্য ব্যবহৃত হয়।
 */