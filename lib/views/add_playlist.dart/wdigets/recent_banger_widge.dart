import 'package:banger_drop/consts/consts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class RecentBangerWidget extends StatelessWidget {
  final String artist;
  final String title;
  final String imageUrl;
  final VoidCallback onPlay;
  final VoidCallback onDownload;
  final bool isSelected;

  const RecentBangerWidget({
    Key? key,
    required this.artist,
    required this.title,
    required this.imageUrl,
    required this.onPlay,
    required this.onDownload,
    this.isSelected = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Circular outline for selection
          Container(
            width: 20,
            height: 20,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? Colors.purpleAccent : Colors.grey,
                width: 2,
              ),
            ),
            child:
                isSelected
                    ? Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.purpleAccent,
                        ),
                      ),
                    )
                    : null,
          ),

          // Song Image
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: CachedNetworkImage(
              imageUrl: imageUrl,
              width: 48,
              height: 48,
              fit: BoxFit.cover,
              placeholder:
                  (context, url) =>
                      Container(width: 48, height: 48, color: Colors.grey),
              errorWidget:
                  (context, url, error) =>
                      const Icon(Icons.music_note, color: Colors.white),
            ),
          ),

          const SizedBox(width: 12),

          // Song Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 200.w,
                  child: Text(
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    title,
                    style: appThemes.Medium.copyWith(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  artist,
                  style: appThemes.small.copyWith(
                    color: Colors.grey[400],
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
