import 'package:banger_drop/consts/consts.dart';
import 'package:banger_drop/views/widgets/loading_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class roundButton extends StatelessWidget {
  final String text;
  final Gradient? backgroundGradient;
  final Color borderColor;
  final Color textColor;
  final VoidCallback onPressed;
  final loading;

  const roundButton({
    Key? key,
    required this.text,
    this.backgroundGradient,
    required this.borderColor,
    required this.textColor,
    required this.onPressed,
    this.loading = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final defaultGradient =
        backgroundGradient ??
        LinearGradient(colors: [Colors.black, Colors.black]);

    return GestureDetector(
      onTap: onPressed,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
        elevation: 10,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
          decoration: BoxDecoration(
            gradient: defaultGradient,
            border: Border.all(color: borderColor, width: 1),
            borderRadius: BorderRadius.circular(40),
          ),
          child: Center(
            child:
                loading
                    ? LoadingWidget(color: appColors.white)
                    : Text(
                      text,
                      style: appThemes.Medium.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
          ),
        ),
      ),
    );
  }
}

class GradientDropButton extends StatelessWidget {
  final VoidCallback onTap;
  final String text;

  const GradientDropButton({
    super.key,
    required this.onTap,
    this.text = "DROP",
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF7B2FF7), Color(0xFFFF3CAC)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 20,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }
}

class RectengleButton extends StatelessWidget {
  final String text;
  final Gradient? backgroundGradient;
  final Color borderColor;
  final Color textColor;
  final VoidCallback onPressed;

  const RectengleButton({
    Key? key,
    required this.text,
    this.backgroundGradient,
    required this.borderColor,
    required this.textColor,
    required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final defaultGradient =
        backgroundGradient ??
        LinearGradient(colors: [Colors.transparent, Colors.transparent]);

    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
        decoration: BoxDecoration(
          gradient: defaultGradient,
          border: Border.all(color: borderColor, width: 1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              color: textColor,
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
