

import 'package:flutter/material.dart';
import 'package:my_chat_app/pages/register_page.dart';
import 'package:my_chat_app/pages/rooms_page.dart';
import 'package:my_chat_app/utils/constants.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({Key? key}) : super(key: key);

  @override
  SplashPageState createState() => SplashPageState();
}

class SplashPageState extends State<SplashPage> with SingleTickerProviderStateMixin {
  // Color palette extracted from your image
  static const Color brandPurple = Color(0xFF7367F0);

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // 1. Initialize Animation Controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    // 2. Define Fade Effect
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );

    // 3. Define Scale Effect (Fixed the "backOut" error to "easeOutBack")
    _scaleAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutBack, // This gives the "pop" and settle effect
      ),
    );

    // Start animation and logic
    _animationController.forward();
    _getInitialSession();
  }

  Future<void> _getInitialSession() async {
    // Keeps the splash visible for 3 seconds total
    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;

    try {
      final session = Supabase.instance.client.auth.currentSession;

      if (session == null) {
        Navigator.of(context).pushAndRemoveUntil(RegisterPage.route(), (_) => false);
      } else {
        Navigator.of(context).pushAndRemoveUntil(RoomsPage.route(), (_) => false);
      }
    } catch (error) {
      // ignore: use_build_context_synchronously
      context.showErrorSnackBar(
        message: 'Error occurred during session refresh',
      );

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(RegisterPage.route(), (_) => false);
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: brandPurple,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // LOGO BOX - Matches your image exactly
                Container(
                  width: 130,
                  height: 130,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(40),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 25,
                        offset: const Offset(0, 10),
                      )
                    ],
                  ),
                  child: const Icon(
                    Icons.chat_bubble_rounded,
                    size: 65,
                    color: brandPurple,
                  ),
                ),
                const SizedBox(height: 35),

                // APP TITLE
                const Text(
                  "ChatApp",
                  style: TextStyle(
                    fontSize: 40,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 12),

                // SUBTITLE
                Text(
                  "Connect with Friends Instantly",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 70),

                // LOADING INDICATOR
                const CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/*
এই SplashPage-টি আপনার অ্যাপের জন্য একজন "স্মার্ট গেট কিপার" হিসেবে কাজ করে। এর মূল কাজগুলো হলো:

1. ব্যান্ডিং ও অ্যানিমেশন: এটি সুন্দর একটি অ্যানিমেশনের মাধ্যমে আপনার অ্যাপের লোগো এবং নাম প্রদর্শন করে, যা ব্যবহারকারীকে একটি প্রিমিয়াম অভিজ্ঞতা দেয়।
2. সেশন যাচাই (Session Check): অ্যাপটি খোলার সাথে সাথে এটি সুপাবেস (Supabase) ডাটাবেস চেক করে দেখে যে ইউজারের আগের কোনো লগইন সেশন সংরক্ষিত আছে কি না।
3. সঠিক পথে চালনা (Redirection Logic): সেশন চেক করার পর এটি সিদ্ধান্ত নেয় ইউজার কোথায় যাবে:
    -যদি লগইন করা থাকে, তবে সরাসরি RoomsPage (চ্যাট লিস্ট)-এ পাঠিয়ে দেয়।
    -যদি লগইন করা না থাকে, তবে তাকে RegisterPage-এ নিয়ে যায়।

4. ত্রুটি নিয়ন্ত্রণ (Error Handling): সেশন চেক করার সময় ইন্টারনেটে বা টেকনিক্যাল কোনো সমস্যা হলে এটি ব্যবহারকারীকে একটি মেসেজ (SnackBar) দেখায় এবং নিরাপদভাবে রেজিস্ট্রেশন পেজে পাঠিয়ে দেয়।
 */