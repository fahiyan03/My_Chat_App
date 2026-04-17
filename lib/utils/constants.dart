import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase client
final supabase = Supabase.instance.client;      //final-> একবার ভ্যালু সেট করলে আর পরিবর্তন করা যাবে না (Runtime constant)।
                                                //Supabase -> পুরো অ্যাপ থেকে ডাটাবেস এক্সেস করার জন্য একটি শর্টকাট রেফারেন্স।
                                                //instance.client -> Supabase-এর সব ফিচার (Auth, Database) কল করার মূল মাধ্যম।
/// Simple preloader inside a Center widget
const preloader =                               //const ->    অ্যাপ চলার সময় মেমোরি বাঁচায় কারণ এটি কখনো পরিবর্তন হয় না।
                                                //preloader ->  ডাটা লোড হওয়ার সময় স্ক্রিনে ঘোরানো এনিমেশন (Loading circle) দেখায়।
    Center(child: CircularProgressIndicator(color: Colors.orange));

/// Simple sized box to space out form elements
const spacer = SizedBox(width: 16, height: 16);  //spacer -> দুটি উইজেটের মাঝখানে খালি জায়গা (Gap) তৈরি করার জন্য ব্যবহৃত হয়।

/// Some padding for all the forms to use
const formPadding = EdgeInsets.symmetric(vertical: 20, horizontal: 16);

/// Error message to display the user when unexpected error occurs.
const unexpectedErrorMessage = 'Unexpected error occured.';

/// Basic theme to change the look and feel of the app
final appTheme = ThemeData.light().copyWith(        //copyWith-> ডিফল্ট থিমের ওপর কিছু নির্দিষ্ট পরিবর্তন (যেমন কালার চ্যাঞ্জ) করার অনুমতি দেয়।
  primaryColorDark: Colors.orange,
  appBarTheme: const AppBarTheme(
    elevation: 1,           //elevation-> অ্যাপবার বা উইজেটের নিচে হালকা ছায়া (Shadow) তৈরি করে গভীরতা বোঝায়।
    backgroundColor: Colors.white,
    iconTheme: IconThemeData(color: Colors.black),
    titleTextStyle: TextStyle(
      color: Colors.black,
      fontSize: 18,
    ),
  ),
  primaryColor: Colors.orange,
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: Colors.orange,
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      foregroundColor: Colors.white,
      backgroundColor: Colors.orange,
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    floatingLabelStyle: const TextStyle(
      color: Colors.orange,
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(
        color: Colors.grey,
        width: 2,
      ),
    ),
    focusColor: Colors.orange,
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(
        color: Colors.orange,
        width: 2,
      ),
    ),
  ),
);

/// Set of extension methods to easily display a snackbar
extension ShowSnackBar on BuildContext {         //extension -> বিদ্যমান কোনো ক্লাসে (এখানে BuildContext) নতুন ফিচার যোগ করা।
                                                  //BuildContext -> উইজেটটি ট্রি-তে কোথায় আছে তা নির্ধারণ করে এবং থিম বা স্ন্যাকবার দেখাতে সাহায্য করে।
  /// Displays a basic snackbar
  void showSnackBar({                             //showSnackBar-> একটি ফাংশন যা ব্যবহার করে অ্যাপ্লিকেশনের স্ক্রিনের নিচের দিকে একটি সংক্ষিপ্ত পপ-আপ বার্তা বা SnackBar প্রদর্শন করা হয়
    required String message,
    Color? backgroundColor,
  }) {
    ScaffoldMessenger.of(this).showSnackBar(SnackBar(     //ScaffoldMessenger-> স্ক্রিনের নিচে ছোট মেসেজ বক্স (SnackBar) দেখানোর দায়িত্ব পালন করে।
      content: Text(message),
      backgroundColor: backgroundColor,
    ));
  }

  /// Displays a red snackbar indicating error
  void showErrorSnackBar({required String message}) {
    showSnackBar(message: message, backgroundColor: Colors.red);
  }
}
/*
এই ফাইলটিকে বলা হয় একটি Utility বা Constants ফাইল। এর কাজগুলো নিচে দেওয়া হলো:
    Global Access: supabase ভ্যারিয়েবলটি ডিফাইন করার ফলে এখন যেকোনো পেজ থেকে খুব সহজে ডাটাবেসের সাথে যোগাযোগ করা যাবে।
    Uniform UI: এখানে appTheme তৈরি করা হয়েছে যাতে পুরো অ্যাপের সব বাটন, ইনপুট বক্স এবং হেডার একই রকম (অরেঞ্জ থিম) দেখতে হয়।
    Reusable Widgets: preloader বা spacer এর মতো ছোট ছোট উইজেটগুলো বারবার না লিখে এক জায়গা থেকেই পুরো অ্যাপে ব্যবহার করা সম্ভব।
    Easy Messaging: extension ব্যবহার করার ফলে এখন যেকোনো পেজে খুব সহজে context.showErrorSnackBar() লিখে ইউজারকে ভুলের বার্তা দেখানো যাবে।
 */