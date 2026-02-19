import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SocialIconsRow extends StatelessWidget {
  final String googleIconPath;
  final String facebookIconPath;
  final String appleIconPath;
  final String twitterIconPath;

  final VoidCallback onGoogleTap;
  final VoidCallback onFacebookTap;
  final VoidCallback onAppleTap;
  final VoidCallback onTwitterTap;

  const SocialIconsRow({
    Key? key,
    required this.googleIconPath,
    required this.facebookIconPath,
    required this.appleIconPath,
    required this.twitterIconPath,
    required this.onGoogleTap,
    required this.onFacebookTap,
    required this.onAppleTap,
    required this.onTwitterTap,
  }) : super(key: key);

  Widget _buildSocialButton(String imagePath, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Image.asset(imagePath, width: 60.w, height: 70.h),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildSocialButton(googleIconPath, onGoogleTap),
        _buildSocialButton(facebookIconPath, onFacebookTap),
        _buildSocialButton(appleIconPath, onAppleTap),
      ],
    );
  }
}
