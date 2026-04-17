
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:my_chat_app/pages/login_page.dart';
import 'package:my_chat_app/pages/rooms_page.dart';
import 'package:my_chat_app/utils/constants.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({Key? key, required this.isRegistering}) : super(key: key);

  static Route<void> route({bool isRegistering = false}) { //static Route: এটি একটি হেল্পার মেথড যা অন্য পেজ থেকে এই পেজে নেভিগেট করা সহজ করে দেয়।
    return MaterialPageRoute(
      builder: (context) => RegisterPage(isRegistering: isRegistering),
    );
  }

  final bool isRegistering;

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final bool _isLoading = false;

  final _formKey = GlobalKey<FormState>(); //GlobalKey<FormState>() -> পুরো ফর্মের অবস্থা (যেমন: ভ্যালিডেশন) ট্র্যাক করার জন্য একটি ইউনিক আইডি।

  final _emailController = TextEditingController();  //TextEditingController -> ইনপুট ফিল্ডে ইউজার যা লিখছেন তা পড়া এবং কন্ট্রোল করার টুল।
  final _passwordController = TextEditingController();
  final _usernameController = TextEditingController();

  late final StreamSubscription<AuthState> _authSubscription;
  //StreamSubscription -> কোনো ডাটা স্ট্রীম (যেমন Auth State) সারাক্ষণ মনিটর করার জন্য ব্যবহৃত হয়।

  @override
  void initState() {  //initState -> একটি উইজেটের "শুরু করার জায়গা" যা উইজেটটি তৈরি হওয়ার সাথে সাথে স্বয়ংক্রিয়ভাবে একবারই রান করে
    super.initState();

    bool haveNavigated = false;
    // Listen to auth state to redirect user when the user clicks on confirmation link
    _authSubscription = supabase.auth.onAuthStateChange.listen((data) {
      //onAuthStateChange -> ইউজারের লগইন বা লগআউট অবস্থা পরিবর্তন হলে তাৎক্ষণিকভাবে তা জানতে সাহায্য করে।
      final session = data.session;
      if (session != null && !haveNavigated) {
        haveNavigated = true;
        Navigator.of(context).pushReplacement(RoomsPage.route());  //pushReplacement -> নতুন পেজে যাওয়ার সময় বর্তমান পেজটি হিস্ট্রি থেকে সরিয়ে ফেলে।
      }
    });
  }

  @override
  void dispose() {  //dispose -> মেমোরি লিক বন্ধ করতে যখন পেজটি বন্ধ হয় তখন সাবস্ক্রিপশন বা কন্ট্রোলারগুলো ক্লিয়ার করে।
    super.dispose();

    // Dispose subscription when no longer needed
    _authSubscription.cancel();
  }

  Future<void> _signUp() async {
    final isValid = _formKey.currentState!.validate();  //validate -> ফর্মে দেওয়া ডাটা সঠিক কি না (যেমন পাসওয়ার্ড ৬ অক্ষরের কি না) তা চেক করে।
    if (!isValid) {
      return;
    }
    final email = _emailController.text;
    final password = _passwordController.text;
    final username = _usernameController.text;
    try {
      await supabase.auth.signUp(  //signUp ->  Supabase সার্ভারে ইউজারের ডাটা পাঠিয়ে নতুন একাউন্ট তৈরি করে।
        email: email,
        password: password,
        data: {'username': username},
        emailRedirectTo: 'io.supabase.chat://login',  //emailRedirectTo ->   ইমেইল ভেরিফিকেশনের পর ইউজারকে আবার অ্যাপে ফিরিয়ে আনার লিঙ্ক।
      );
      context.showSnackBar(
          message: 'Please check your inbox for confirmation email.');
    } on AuthException catch (error) {  //AuthException ->  শুধুমাত্র লগইন বা সাইন-আপ সংক্রান্ত ভুলগুলো ধরার জন্য নির্দিষ্ট এরর ক্লাস।
      context.showErrorSnackBar(message: error.message);
    } catch (error) {
      debugPrint(error.toString());
      context.showErrorSnackBar(message: unexpectedErrorMessage);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Register'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: formPadding,
          children: [
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                label: Text('Email'),
              ),
              validator: (val) {
                if (val == null || val.isEmpty) {
                  return 'Required';
                }
                return null;
              },
              keyboardType: TextInputType.emailAddress,
            ),
            spacer,
            TextFormField(
              controller: _passwordController,
              obscureText: true,  //obscureText ->  পাসওয়ার্ড টাইপ করার সময় সেটি ডট (●●●) আকারে দেখানোর জন্য ব্যবহৃত হয়।
              decoration: const InputDecoration(
                label: Text('Password'),
              ),
              validator: (val) {
                if (val == null || val.isEmpty) {
                  return 'Required';
                }
                if (val.length < 6) {
                  return '6 characters minimum';
                }
                return null;
              },
            ),
            spacer,
            TextFormField(
              controller: _usernameController,
              decoration: const InputDecoration(
                label: Text('Username'),
              ),
              validator: (val) {
                if (val == null || val.isEmpty) {
                  return 'Required';
                }
                final isValid = RegExp(r'^[A-Za-z0-9_]{3,24}$').hasMatch(val);
                //RegExp -> ইউজারনেমটি নির্দিষ্ট প্যাটার্ন (যেমন: শুধু অক্ষর ও সংখ্যা) মেনে চলছে কি না তা যাচাই করে।
                if (!isValid) {
                  return '3-24 long with alphanumeric or underscore';
                }
                return null;
              },
            ),
            spacer,
            ElevatedButton(
              onPressed: _isLoading ? null : _signUp,
              child: const Text('Register'),
            ),
            spacer,
            TextButton(
                onPressed: () {
                  Navigator.of(context).push(LoginPage.route());
                },
                child: const Text('I already have an account'))
          ],
        ),
      ),
    );
  }
}

/*
এই RegisterPage-এর মূল কাজ হলো নতুন ইউজার তৈরি করা এবং তাদের তথ্য যাচাই করা। এখানে প্রধান বিষয়গুলো হলো:
১. Form Validation: ইউজার ইমেইল বা পাসওয়ার্ড খালি রাখলে বা ভুল ইউজারনেম দিলে এটি তাৎক্ষণিকভাবে 'Required' বা এরর মেসেজ দেখায়।
২. Supabase Integration: _signUp ফাংশনের মাধ্যমে ডাটা সরাসরি Supabase-এ চলে যায় এবং একটি কনফার্মেশন ইমেইল পাঠানো হয়।
৩. Real-time Auth Listening: অ্যাপটি _authSubscription এর মাধ্যমে খেয়াল রাখে ইউজার কখন ইমেইল কনফার্ম করে লগইন করছেন। লগইন হওয়া মাত্রই তাকে RoomsPage-এ পাঠিয়ে দেওয়া হয়।
৪. Security: পাসওয়ার্ডের জন্য obscureText এবং ইউজারনেমের জন্য RegExp ব্যবহার করে অ্যাপের ডাটা এন্ট্রি নিরাপদ করা হয়েছে।

 */