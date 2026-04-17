import 'package:flutter/material.dart';
import 'package:my_chat_app/utils/constants.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  static Route<void> route() {
    return MaterialPageRoute(builder: (context) => const LoginPage());
  }

  @override
  _LoginPageState createState() => _LoginPageState();  // _LoginPageState -> লগইন পেজের অভ্যন্তরীণ ডাটা এবং লজিক (যেমন: লোডিং অবস্থা) পরিচালনা করে।
}

class _LoginPageState extends State<LoginPage> {
  bool _isLoading = false;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  Future<void> _signIn() async {
    setState(() {
      _isLoading =
      true; //_isLoading ->  লগইন প্রসেস চলাকালীন বাটনটি ডিজেবল রাখতে এবং ইউজারকে বোঝাতে সাহায্য করে।
    });
    try {
      await supabase.auth.signInWithPassword(
        //signInWithPassword  ->  Supabase-এর এই মেথডটি ডাটাবেসে ইউজার আছে কি না এবং পাসওয়ার্ড ঠিক কি না তা যাচাই করে।
        email: _emailController.text,
        password: _passwordController.text,
      );
    } on AuthException catch (error) { //on AuthException ->  শুধুমাত্র লগইন সংক্রান্ত ভুল (যেমন: ভুল পাসওয়ার্ড) আলাদাভাবে ধরার জন্য।
      context.showErrorSnackBar(message: error.message);
    } catch (_) { // catch (_)  ->   কোনো নির্দিষ্ট নাম ছাড়াই যেকোনো অজানা এরর ধরার জন্য _ ব্যবহার করা হয়েছে।
      context.showErrorSnackBar(message: unexpectedErrorMessage);
    }
    if (mounted) {
      setState(() { // setState -> এটি কল করলে UI রিফ্রেশ হয়; যেমন লোডিং শুরু হলে স্ক্রিনে পরিবর্তন দেখানোর জন্য।
        _isLoading = true;
      });
    }
  }

  @override
  void dispose() {
    //dispose -> যখন ইউজার এই পেজ থেকে চলে যায়, তখন কন্ট্রোলারগুলো মেমোরি থেকে মুছে ফেলে পারফরম্যান্স ঠিক রাখে।
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign In')),
      body: ListView( // ListView  ->  ফর্মের এলিমেন্টগুলো উপর-নিচে সাজায় এবং স্ক্রিন ছোট হলে স্ক্রল করার সুবিধা দেয়।
        padding: formPadding,
        children: [
          TextFormField(
            controller: _emailController,
            decoration: const InputDecoration(labelText: 'Email'),
            //labelText  ->  ইনপুট ফিল্ডের ভেতরে ছোট করে লেখা থাকে (যেমন: 'Email') যা ইউজারকে গাইড করে।
            keyboardType: TextInputType.emailAddress,
          ),
          spacer,
          TextFormField(
            controller: _passwordController,
            decoration: const InputDecoration(labelText: 'Password'),
            obscureText: true,
          ),
          spacer,
          ElevatedButton(
            onPressed: _isLoading ? null : _signIn,
            // onPressed   -> বাটনে ক্লিক করলে কোন ফাংশনটি (_signIn) চলবে তা নির্ধারণ করে।
            // null  -> যখন _isLoading ট্রু থাকে, তখন বাটনকে null করে দেওয়া হয় যাতে ইউজার বারবার ক্লিক করতে না পারে।
            child: const Text('Login'),
          ),
        ],
      ),
    );
  }
}

/*
এই LoginPage কোডটির মূল উদ্দেশ্য হলো একজন ইউজারকে ভেরিফাই করা। এর কাজগুলো হলো:
১. User Input Collection: TextEditingController এর মাধ্যমে ইউজারের ইমেইল এবং পাসওয়ার্ড সংগ্রহ করা হয়।
২. Authentication Call: signInWithPassword ব্যবহার করে ডাটাবেসে তথ্য পাঠানো হয়। যদি তথ্য সঠিক হয়, তবে Supabase নিজে থেকেই ইউজারের সেশন শুরু করে দেয়।
৩. Loading Feedback: লগইন বাটনে ক্লিক করার পর কাজ চলাকালীন বাটনটি ডিজেবল হয়ে যায় (Loading state), যাতে অ্যাপটি হ্যাং না হয় বা ডাবল রিকোয়েস্ট না যায়।
৪. Error Feedback: যদি ইমেইল বা পাসওয়ার্ড ভুল হয়, তবে এটি আগের ফাইলে তৈরি করা showErrorSnackBar ব্যবহার করে লাল রঙের সতর্কবার্তা দেখায়।
 */
