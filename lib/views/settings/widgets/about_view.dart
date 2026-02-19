import 'package:banger_drop/consts/consts.dart';
import 'package:banger_drop/views/settings/widgets/Terms&condition.dart';
import 'package:banger_drop/views/spalsh/widgets/privacy_policy.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AboutScreen extends StatelessWidget {
  AboutScreen({super.key});

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
                            Text('Bangerdrop', style: appThemes.Large),
                            Text(
                              'Version 1.0.0',
                              style: appThemes.small.copyWith(
                                color: appColors.textGrey,
                                fontFamily: 'Sans',
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 30),

                      Text('About This App', style: appThemes.Large),
                      SizedBox(height: 10),
                      Text(
                        'BangerDrop is a music social network that lets users share the music that they love. Created in order to make it easy to share your favorite music as soon as it\'s released. Create your circle of friends as you would on any other network, and send the rare gems (Bangers) you discover as previews for your friends and the whole world to enjoy. No need to share a link via a chat window, or go through several different networks, BangerDrop lets you quickly share and showcase recent tracks or those with musical potential with your friends and family, or the whole web.',
                        style: appThemes.small.copyWith(fontFamily: 'Sans'),
                      ),

                      SizedBox(height: 30),

                      Text('Developed by', style: appThemes.Large),
                      SizedBox(height: 10),
                      Text(
                        'Redstone Ai\nPeshawar, Pakistan',
                        style: appThemes.small.copyWith(fontFamily: 'Sans'),
                      ),

                      SizedBox(height: 30),

                      Text('Contact', style: appThemes.Large.copyWith()),
                      SizedBox(height: 10),
                      Text(
                        'Email: bangerdropmusic@gmail.com',
                        style: appThemes.small.copyWith(fontFamily: 'Sans'),
                      ),

                      SizedBox(height: 30),

                      Row(
                        children: [
                          TextButton(
                            onPressed: () {
                              Get.to(() => PrivacyPolicy());
                            },
                            child: Text(
                              'Privacy Policy',
                              style: appThemes.small.copyWith(),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Get.to(() => TermsAndCondition());
                            },
                            child: Text(
                              'Terms & Conditions',
                              style: appThemes.small.copyWith(),
                            ),
                          ),
                        ],
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
}
