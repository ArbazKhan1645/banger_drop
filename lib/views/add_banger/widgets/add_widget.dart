import 'package:flutter/material.dart';
import 'package:banger_drop/consts/consts.dart';

class SplitContainer extends StatefulWidget {
  final VoidCallback leftTap;
  final VoidCallback rightTap;

  const SplitContainer({
    super.key,
    required this.rightTap,
    required this.leftTap,
  });

  @override
  State<SplitContainer> createState() => _SplitContainerState();
}

class _SplitContainerState extends State<SplitContainer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  static const double totalWidth = 350;
  static const double spacing = 8;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _animation = Tween<double>(
      begin: 1.0,
      end: 0.5,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    // Automatically trigger the split animation on first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: totalWidth,
      height: 100,
      decoration: BoxDecoration(
        color: appColors.purple,
        borderRadius: BorderRadius.circular(12),
      ),
      child: AnimatedBuilder(
        animation: _animation,
        builder: (_, __) {
          double leftWidth = (totalWidth - spacing) * _animation.value;
          double rightWidth = (totalWidth - spacing) - leftWidth;

          return Row(
            children: [
              SizedBox(
                width: leftWidth,
                child: GestureDetector(
                  onTap: widget.leftTap,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.purple,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(12),
                        bottomLeft: Radius.circular(12),
                      ),
                    ),
                    child: const Center(
                      child: Text(
                        "BANGER",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: spacing),
              SizedBox(
                width: rightWidth,
                child: GestureDetector(
                  onTap: widget.rightTap,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.pinkAccent,
                      borderRadius: BorderRadius.only(
                        topRight: Radius.circular(12),
                        bottomRight: Radius.circular(12),
                      ),
                    ),
                    child: const Center(
                      child: Text(
                        "PLAYLIST",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
