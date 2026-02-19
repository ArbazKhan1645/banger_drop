import 'package:banger_drop/consts/consts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class MusicPlayerWidget extends StatefulWidget {
  final String songTitle;
  final String artistName;
  final String duration;
  final String year;
  final double currentPosition;
  final bool isPlaying;
  final VoidCallback? onPlayPause;
  final VoidCallback? onNext;
  final VoidCallback? onPrevious;
  final VoidCallback? onShare;
  final VoidCallback? onShuffle;
  final Function(double)? onSeek;

  const MusicPlayerWidget({
    Key? key,
    this.songTitle = "Taste",
    this.artistName = "Sabrina Carpenter",
    this.duration = "2:37",
    this.year = "2024",
    this.currentPosition = 0.3,
    this.isPlaying = false,
    this.onPlayPause,
    this.onNext,
    this.onPrevious,
    this.onShare,
    this.onShuffle,
    this.onSeek,
  }) : super(key: key);

  @override
  State<MusicPlayerWidget> createState() => _MusicPlayerWidgetState();
}

class _MusicPlayerWidgetState extends State<MusicPlayerWidget> {
  late double _currentPosition;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _currentPosition = widget.currentPosition;
    _isPlaying = widget.isPlaying;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.transparent, Colors.black],

          end: Alignment.bottomCenter,
          begin: Alignment.topCenter,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header with song info and share button
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      widget.songTitle,
                      style: appThemes.Large.copyWith(fontSize: 25.sp),
                    ),
                    SizedBox(height: 4),
                    Text(
                      widget.artistName,
                      style: appThemes.Medium.copyWith(fontFamily: 'Sans'),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  GestureDetector(
                    onTap: widget.onShare,
                    child: Icon(
                      Icons.share_outlined,
                      color: Colors.white.withOpacity(0.8),
                      size: 24,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    widget.duration,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ],
          ),
          // Row(
          //   mainAxisAlignment: MainAxisAlignment.end,
          //   children: [

          //   ],
          // ),
          SizedBox(height: 40),

          // Progress slider
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: appColors.pink,
              inactiveTrackColor: Colors.white.withOpacity(0.3),
              thumbColor: Colors.white,
              thumbShape: RoundSliderThumbShape(enabledThumbRadius: 12),
              trackHeight: 4,
              overlayShape: RoundSliderOverlayShape(overlayRadius: 20),
            ),
            child: Slider(
              value: _currentPosition,
              onChanged: (value) {
                setState(() {
                  _currentPosition = value;
                });
                widget.onSeek?.call(value);
              },
            ),
          ),

          SizedBox(height: 32),

          // Control buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Previous button
              IconButton(
                onPressed: widget.onPrevious,

                icon: Icon(Icons.skip_previous, color: Colors.white, size: 32),
              ),

              // Play/Pause button
              GestureDetector(
                onTap: () {
                  setState(() {
                    _isPlaying = !_isPlaying;
                  });
                  widget.onPlayPause?.call();
                },
                child: Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    _isPlaying ? Icons.pause : Icons.play_arrow,
                    color: Color(0xFF2D1B3D),
                    size: 36,
                  ),
                ),
              ),

              // Next button
              IconButton(
                onPressed: widget.onNext,
                icon: Icon(Icons.skip_next, color: Colors.white, size: 32),
              ),
            ],
          ),

          SizedBox(height: 24),

          // Bottom row with shuffle and year
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: widget.onShuffle,
                child: Icon(
                  Icons.shuffle,
                  color: Colors.white.withOpacity(0.7),
                  size: 24,
                ),
              ),
              Text(
                widget.year,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
          SizedBox(height: 30),
        ],
      ),
    );
  }
}
