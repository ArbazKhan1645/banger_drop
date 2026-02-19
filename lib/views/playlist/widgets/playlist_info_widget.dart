import 'package:banger_drop/consts/consts.dart';
import 'package:banger_drop/views/playlist/widgets/playlis_appbar_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get_rx/src/rx_typedefs/rx_typedefs.dart';

class PlaylistInfoWidget extends StatefulWidget {
  const PlaylistInfoWidget({
    super.key,
    required this.onPlayPress,
    required this.artist,
    required this.name,
    required this.id,
    required this.isPlaylist,
    required this.onSharePressed,
    required this.description,
  });

  final Callback onPlayPress;
  final String name;
  final String artist;
  final String id;
  final String description;
  final bool isPlaylist;
  final Callback onSharePressed;

  @override
  State<PlaylistInfoWidget> createState() => _PlaylistInfoWidgetState();
}

class _PlaylistInfoWidgetState extends State<PlaylistInfoWidget> {
  bool _isDescriptionExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 12.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.transparent, Colors.black],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Left Side Info
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: appThemes.Large.copyWith(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  'By ${widget.artist}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: appThemes.Medium.copyWith(
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Sans',
                  ),
                ),
                SizedBox(height: 6.h),
                if (widget.description.trim().isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _isDescriptionExpanded = !_isDescriptionExpanded;
                      });
                    },
                    child: AnimatedContainer(
                      duration: Duration(milliseconds: 200),
                      constraints: BoxConstraints(
                        maxHeight: _isDescriptionExpanded ? 80.h : 38.h,
                      ),
                      child: SingleChildScrollView(
                        physics:
                            _isDescriptionExpanded
                                ? BouncingScrollPhysics()
                                : NeverScrollableScrollPhysics(),
                        child: Text(
                          widget.description,
                          softWrap: true,
                          style: appThemes.small.copyWith(
                            fontFamily: 'Sans',
                            color: appColors.textGrey,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Share + Play Button
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Share button
              Padding(
                padding: EdgeInsets.only(bottom: 8.h),
                child: MiniFavShareWidget(
                  id: widget.id,
                  isPlaylist: false,
                  onSharePressed: widget.onSharePressed,
                ),
              ),

              // Play button
              GestureDetector(
                onTap: widget.onPlayPress,
                child: Card(
                  elevation: 10,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(200.r),
                  ),
                  child: Container(
                    width: 60.w,
                    height: 60.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xff842ED8),
                          Color(0xffDB28A9),
                          Color(0xff9D1DCA),
                        ],
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.play_arrow_rounded,
                        color: appColors.white,
                        size: 30.sp,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
