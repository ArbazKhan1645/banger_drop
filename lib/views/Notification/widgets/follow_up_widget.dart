import 'package:banger_drop/consts/consts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class FriendRequestTile extends StatelessWidget {
  final String imageUrl;
  final String name;
  final VoidCallback onConfirm;
  final VoidCallback onDelete;

  const FriendRequestTile({
    super.key,
    required this.imageUrl,
    required this.name,
    required this.onConfirm,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(5.0),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF6A0DAD).withOpacity(.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            // Profile image
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(shape: BoxShape.circle),
              child: CircleAvatar(
                radius: 25.r,
                backgroundColor: Colors.white,
                child: ClipOval(
                  child: CachedNetworkImage(
                    imageUrl: imageUrl,
                    width: 80.r,
                    height: 80.r,
                    fit: BoxFit.cover,
                    placeholder:
                        (context, url) =>
                            const CircularProgressIndicator(strokeWidth: 2),
                    errorWidget:
                        (context, url, error) =>
                            const Icon(Icons.person, color: Colors.black),
                  ),
                ),
              ),
            ),

            const SizedBox(width: 12),

            // Name
            Expanded(
              child: Text(
                name,
                style: appThemes.Medium.copyWith(
                  fontFamily: 'Sans',
                  fontWeight: FontWeight.bold,
                ),

                overflow: TextOverflow.ellipsis,
              ),
            ),

            const SizedBox(width: 8),

            // Confirm button (small)
            SizedBox(
              height: 30,
              child: ElevatedButton(
                onPressed: onConfirm,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  backgroundColor: appColors.purple,
                  minimumSize: Size(60, 30),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                child: Text("Confirm", style: appThemes.small),
              ),
            ),

            const SizedBox(width: 6),

            // Delete button (small)
            SizedBox(
              height: 30,
              child: ElevatedButton(
                onPressed: onDelete,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  backgroundColor: Colors.grey.shade400,
                  minimumSize: Size(50, 30),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                child: Text("Delete", style: appThemes.small),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
