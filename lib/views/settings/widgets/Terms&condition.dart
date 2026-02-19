import 'package:banger_drop/consts/consts.dart';
import 'package:banger_drop/views/spalsh/widgets/privacy_policy.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class TermsAndCondition extends StatelessWidget {
  TermsAndCondition({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   title:  Text('About'),
      //   centerTitle: true,
      //   backgroundColor: Colors.transparent,
      //   forceMaterialTransparency: false,
      // ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(
                    'assets/images/Picture1.png',
                  ), // Replace with your image path
                  fit: BoxFit.cover,
                ),
              ),
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 50),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [const BackButton(color: Colors.white)],
                      ),
                      Center(
                        child: Column(
                          children: [
                            Image.asset('assets/images/Group (1).png'),
                            SizedBox(height: 10),
                            Text('Bager Drop', style: appThemes.Large),
                          ],
                        ),
                      ),

                      SizedBox(height: 30),

                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: 'Terms & Conditions\n',
                              style: appThemes.small.copyWith(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Sans',
                              ),
                            ),
                            TextSpan(
                              text: 'Last updated: 26th of June 2025\n\n',
                              style: appThemes.small.copyWith(
                                fontSize: 16,
                                fontStyle: FontStyle.italic,
                                fontFamily: 'Sans',
                              ),
                            ),
                            TextSpan(
                              text:
                                  'Welcome to Bangerdrop! These Terms & Conditions govern your access and use of the platform. By accessing or using Bangerdrop, you agree to be bound by these terms.\n\n',
                              style: appThemes.small.copyWith(
                                fontFamily: 'Sans',
                              ),
                            ),
                            section('1. Acceptance of Terms'),
                            TextSpan(
                              text:
                                  'By creating an account or using Bangerdrop, you confirm that you accept these terms and that you agree to comply with them. If you do not agree, you must not use Bangerdrop.\n\n',
                              style: appThemes.small.copyWith(
                                fontFamily: 'Sans',
                              ),
                            ),
                            section('2. User Responsibilities'),
                            TextSpan(
                              text:
                                  'You agree to:\n'
                                  '• Provide accurate and current information when registering an account.\n'
                                  '• Keep your password confidential and not share your account with others.\n'
                                  '• Use the Platform only for lawful purposes and in accordance with all applicable laws and regulations.\n'
                                  '• Not engage in any activity that may interfere with or disrupt Bangerdrop or its services.\n\n',
                              style: appThemes.small.copyWith(
                                fontFamily: 'Sans',
                              ),
                            ),
                            section('3. Content'),
                            TextSpan(
                              text:
                                  '• User-Generated Content: You are responsible for all content you post or share on Bangerdrop.\n'
                                  '• Prohibited Content: You must not post or share content that is illegal, harmful, threatening, abusive, harassing, defamatory, or otherwise objectionable.\n'
                                  '• Rights: By posting content, you grant Bangerdrop a non-exclusive, royalty-free license to use, display, and distribute your content in connection with the platform.\n\n',
                              style: appThemes.small.copyWith(
                                fontFamily: 'Sans',
                              ),
                            ),
                            section('4. Privacy'),
                            TextSpan(
                              text:
                                  'Your privacy is important to us. Please review our Privacy Policy to understand how we collect, use, and protect your personal information.\n\n',
                              style: appThemes.small.copyWith(
                                fontFamily: 'Sans',
                              ),
                            ),
                            section('5. Account Termination'),
                            TextSpan(
                              text:
                                  'Bangerdrop reserves the right to suspend or terminate your account at any time without notice if you violate these Terms or engage in conduct deemed harmful to the platform or its users.\n\n',
                              style: appThemes.small.copyWith(
                                fontFamily: 'Sans',
                              ),
                            ),
                            section('6. Limitation of Liability'),
                            TextSpan(
                              text:
                                  'Bangerdrop is provided “as is” and “as available.” We do not guarantee that the Platform will be uninterrupted, secure, or error-free. We are not liable for any damages or losses arising from your use of Bangerdrop.\n\n',
                              style: appThemes.small.copyWith(
                                fontFamily: 'Sans',
                              ),
                            ),
                            section('7. Changes to Terms'),
                            TextSpan(
                              text:
                                  'We may update these Terms from time to time. The updated version will be indicated by a revised “Last updated” date. Your continued use of the platform after changes are posted constitutes your acceptance of the new terms.\n\n',
                              style: appThemes.small.copyWith(
                                fontFamily: 'Sans',
                              ),
                            ),
                            section('8. Contact Us'),
                            TextSpan(
                              text:
                                  'If you have any questions about these Terms, please contact us at bangerdropmusic@gmail.com.\n',
                              style: appThemes.small.copyWith(
                                fontFamily: 'Sans',
                              ),
                            ),
                          ],
                        ),
                        textAlign: TextAlign.start,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  TextSpan section(String title) {
    return TextSpan(
      text: '$title\n',
      style: appThemes.small.copyWith(
        fontWeight: FontWeight.bold,
        fontSize: 16,
        fontFamily: 'Sans',
      ),
    );
  }
}
