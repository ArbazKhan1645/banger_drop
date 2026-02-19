import 'package:banger_drop/consts/consts.dart';
import 'package:banger_drop/views/widgets/loading_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get_rx/src/rx_typedefs/rx_typedefs.dart';

class PlaylistBuilder extends StatelessWidget {
  final String imageUrl;
  final String playlistName;
  final String artistName;
  final String playlistId;
  final Callback ontap;

  const PlaylistBuilder({
    super.key,
    required this.imageUrl,
    required this.playlistName,
    required this.artistName,
    required this.ontap,
    required this.playlistId,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: GestureDetector(
        onTap: ontap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image container
            Container(
              width: 120.w,
              height: 120.h,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.grey[800],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder:
                      (context, error, stackTrace) =>
                          const Icon(Icons.broken_image, color: Colors.red),
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(child: LoadingWidget(color: appColors.white));
                  },
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Playlist name
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 120.w),
              child: Text(
                playlistName,
                style: appThemes.Large.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 16.sp,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),

            // Artist name
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 120.w),
              child: Text(
                artistName,
                style: appThemes.Medium.copyWith(
                  fontSize: 14.sp,
                  color: appColors.textGrey,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
