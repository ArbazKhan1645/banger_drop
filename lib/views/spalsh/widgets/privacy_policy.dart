import 'package:banger_drop/consts/consts.dart';
import 'package:banger_drop/views/widgets/buttons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

class PrivacyPolicy extends StatelessWidget {
  const PrivacyPolicy({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: appColors.purple,
      // title: Text("Confirmation"),
      content: SingleChildScrollView(
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox(width: 50, height: 50),
                Icon(
                  Icons.privacy_tip_outlined,
                  size: 40.sp,
                  color: appColors.white,
                ),
                IconButton(
                  onPressed: () {
                    Get.back();
                  },
                  icon: Icon(Icons.close, color: appColors.white),
                ),
              ],
            ),
            SizedBox(height: 20),

            Text(
              'Privacy & Policy',
              style: appThemes.Large.copyWith(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            Text(textAlign: TextAlign.left, """Effective Date: June 26, 2025
Welcome to Bangerdrop ! We are committed to protecting your privacy and ensuring the security of your personal information. This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use our platform.
1. Information we collect
a. Information you provide
•	Account and personal information: Name, email address, username, password, profile picture, phone number, date of birth, country/region, …
•	Content: Posts, messages, comments, photos, videos, audios and other content you share.
•	Contact Information: Contacts you choose to share or invite.
b. Information we collect automatically
•	Usage Data: Interactions, likes, follows, and browsing history.
•	Device Information: IP address, browser type, operating system, device identifiers.
•	Cookies and Tracking: We use cookies and similar technologies to enhance your experience.
c. Information from Third Parties
•	Social Logins: If you sign in via third-party accounts (e.g., Google, Facebook), we may receive information as permitted by those services.
2. How we use your information
We use your information to:
•	Provide, operate, and maintain our services.
•	Personalize your experience and recommend content.
•	Communicate with you about updates, security, and support.
•	Analyze usage to improve our platform.
•	Protect against fraud, abuse, or illegal activity.
•	Comply with legal obligations.




3. How we share your information
We may share your information:
•	With other users: Content you post may be visible to others according to your privacy settings.
•	With service providers: For hosting, analytics, customer support, and other services.
•	For legal reasons: To comply with laws, regulations, or legal requests.
•	In business transfers: In case of a merger, acquisition, or sale of assets.
4. Your choices
•	Privacy settings: Control who can see your content and profile.
•	Marketing communications: Opt out of promotional emails via the unsubscribe link.
•	Cookies: Adjust your browser settings to refuse cookies.
5. Data security
We implement technical and organizational measures to protect your data. However, no system is 100% secure.
6. Children’s privacy
Our platform is not intended for children under 13. We do not knowingly collect data from children under 13.
7. International users
Your information may be transferred to and processed in countries outside your own. We take steps to ensure adequate protection.
8. Changes to this policy
We may update this Privacy Policy from time to time. We will notify you of significant changes and update the effective date.
9. Contact Us
If you have questions or concerns about this Privacy Policy, please contact us at:
bangerdropmusic@gmail.com
""", style: appThemes.small),
            Text(
              "By continuing you agree to our terms of services and privacy policy",
              style: appThemes.small.copyWith(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            roundButton(
              text: "Continue",
              backgroundGradient: LinearGradient(
                colors: [Color(0xFF7F00FF), Color(0xFFE100FF)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderColor: appColors.white,
              textColor: appColors.white,
              onPressed: () {
                Get.back();
              },
            ),
          ],
        ),
      ),
    );
  }
}
