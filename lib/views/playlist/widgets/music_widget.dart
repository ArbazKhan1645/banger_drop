import 'package:banger_drop/consts/consts.dart';
import 'package:banger_drop/views/widgets/loading_widget.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:html_unescape/html_unescape.dart';

class Music extends StatefulWidget {
  final String title;
  final String artist;
  final String imageUrl;
  final String bangerId;
  final VoidCallback? onTap;
  final VoidCallback? onshareTap;

  const Music({
    Key? key,
    required this.title,
    required this.artist,
    required this.imageUrl,
    required this.bangerId,
    required this.onTap,
    this.onshareTap,
  }) : super(key: key);

  @override
  State<Music> createState() => _MusicState();
}

class _MusicState extends State<Music> {
  String decodeHtmlEntities(String input) {
    final unescape = HtmlUnescape();
    return unescape.convert(input);
  }

  bool isLoading = false;

  Future<Map<String, dynamic>> _fetchStats() async {
    final doc =
        await FirebaseFirestore.instance
            .collection('Bangers')
            .doc(widget.bangerId)
            .get();
    final data = doc.data() ?? {};
    print("Fetching bangerId: ${widget.bangerId}");
    print("Data fetched: $data");

    return {
      'TotalShares': data['TotalShares'] ?? 0,
      'TotalComments': data['TotalComments'] ?? 0,
      'TotalLikes': data['TotalLikes'] ?? 0,
    };
  }

  Future<void> _showStatsPopup(BuildContext context, Offset position) async {
    setState(() => isLoading = true);

    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;

    final stats = await _fetchStats();

    setState(() => isLoading = false);

    await showMenu(
      context: context,
      position: RelativeRect.fromRect(
        position & const Size(40, 40),
        Offset.zero & overlay.size,
      ),
      color: appColors.purple,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      items: [
        PopupMenuItem(
          enabled: false,
          child: _buildStatRow(Icons.share, "Shares", stats['TotalShares']),
        ),
        PopupMenuItem(
          enabled: false,
          child: _buildStatRow(
            Icons.comment,
            "Comments",
            stats['TotalComments'],
          ),
        ),
        PopupMenuItem(
          enabled: false,
          child: _buildStatRow(Icons.favorite, "Likes", stats['TotalLikes']),
        ),
      ],
    );
  }

  Widget _buildStatRow(IconData icon, String label, int value) {
    return Row(
      children: [
        Icon(icon, color: Colors.white, size: 18),
        const SizedBox(width: 8),
        Text(
          '$label: $value',
          style: const TextStyle(color: Colors.white, fontSize: 14),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: const BoxDecoration(color: Colors.transparent),
        child: Row(
          children: [
            // Album cover
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  widget.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[800],
                      child: const Icon(
                        Icons.music_note,
                        color: Colors.white,
                        size: 24,
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(width: 16),

            // Song info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    decodeHtmlEntities(widget.title),
                    style: appThemes.Medium.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.artist,
                    style: appThemes.small.copyWith(
                      fontFamily: 'Sans',
                      color: appColors.textGrey,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Share button
            IconButton(
              onPressed: widget.onshareTap,
              icon: Icon(Icons.share, color: Colors.white, size: 20.sp),
            ),

            // More menu with loading
            GestureDetector(
              onTapDown: (TapDownDetails details) {
                _showStatsPopup(context, details.globalPosition);
              },
              behavior: HitTestBehavior.opaque,
              child: SizedBox(
                width: 40,
                height: 40,
                child: Center(
                  child:
                      isLoading
                          ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                          : Icon(
                            Icons.more_vert_outlined,
                            color: Colors.white,
                            size: 20.sp,
                          ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
