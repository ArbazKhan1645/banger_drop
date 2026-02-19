import 'dart:convert';

import 'package:banger_drop/consts/consts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:get/get_core/get_core.dart';
import 'package:http/http.dart' as http;

class FeedbackView extends StatefulWidget {
  const FeedbackView({super.key});

  @override
  State<FeedbackView> createState() => _FeedbackViewState();
}

class _FeedbackViewState extends State<FeedbackView> {
  final _formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final messageController = TextEditingController();
  Future<bool> sendEmail({
    required String name,
    required String email,
    required String message,
  }) async {
    const serviceId = 'service_toze0fh';
    const templateId = 'template_7qforin';
    const userId = '3YwRE95-bZRIxuzrq';

    final url = Uri.parse('https://api.emailjs.com/api/v1.0/email/send');

    final response = await http.post(
      url,
      headers: {
        'origin': 'http://localhost',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'service_id': serviceId,
        'template_id': templateId,
        'user_id': userId,
        'template_params': {
          'name': name,
          'email': email,
          'fromemail': email, // ✅ Updated key here
          'message': message,
          'title': 'User Feedback',
          'time': DateTime.now().toString(),
        },
      }),
    );

    return response.statusCode == 200;
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background image
          Positioned.fill(
            child: Image.asset('assets/images/Picture1.png', fit: BoxFit.cover),
          ),

          // Content
          SafeArea(
            child: Padding(
              padding: EdgeInsets.all(20.w),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: () {
                            Get.back();
                          },
                          icon: Icon(Icons.arrow_back, color: appColors.white),
                        ),
                      ],
                    ),
                    Text("We value your feedback", style: appThemes.Large),
                    SizedBox(height: 32.h),

                    /// Name Field
                    TextFormField(
                      controller: nameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputDecoration("Name"),
                      validator:
                          (value) =>
                              value == null || value.isEmpty
                                  ? 'Enter your name'
                                  : null,
                    ),
                    SizedBox(height: 16.h),

                    /// Email Field
                    TextFormField(
                      controller: emailController,
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputDecoration("Email"),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Enter your email';
                        } else if (!value.contains('@')) {
                          return 'Enter a valid email';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16.h),

                    /// Message Field
                    TextFormField(
                      controller: messageController,
                      style: const TextStyle(color: Colors.white),
                      maxLines: 5,
                      decoration: _inputDecoration("Your Message"),
                      validator:
                          (value) =>
                              value == null || value.isEmpty
                                  ? 'Enter your message'
                                  : null,
                    ),
                    SizedBox(height: 32.h),

                    /// Submit Button
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          horizontal: 40.w,
                          vertical: 14.h,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30.r),
                        ),
                      ),
                      onPressed: () async {
                        if (_formKey.currentState!.validate()) {
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder:
                                (_) => const Center(
                                  child: CircularProgressIndicator(),
                                ),
                          );

                          final success = await sendEmail(
                            name: nameController.text.trim(),
                            email: emailController.text.trim(),
                            message: messageController.text.trim(),
                          );

                          Navigator.of(
                            context,
                          ).pop(); // Close the loading dialog

                          if (success) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Thank you for your feedback!'),
                              ),
                            );
                            nameController.clear();
                            emailController.clear();
                            messageController.clear();
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Failed to send feedback. Try again.',
                                ),
                              ),
                            );
                          }
                        }
                      },

                      child: Text(
                        'Submit',
                        style: TextStyle(
                          color: appColors.purple,
                          fontWeight: FontWeight.bold,
                          fontSize: 16.sp,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.white70),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: const BorderSide(color: Colors.white30),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: const BorderSide(color: Colors.white),
      ),
    );
  }
}
