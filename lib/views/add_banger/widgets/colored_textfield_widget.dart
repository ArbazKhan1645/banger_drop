import 'package:banger_drop/consts/consts.dart';
import 'package:flutter/material.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final List<String> suggestions;
  final int maxLines;
  final String hint;
  final Widget? suffixIcon;

  CustomTextField({
    Key? key,
    required this.controller,
    required this.suggestions,
    required this.maxLines,
    required this.hint,
    this.suffixIcon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Autocomplete<String>(
      optionsBuilder: (TextEditingValue textEditingValue) {
        if (textEditingValue.text == '') return const Iterable<String>.empty();
        return suggestions.where((String option) {
          return option.toLowerCase().contains(
            textEditingValue.text.toLowerCase(),
          );
        });
      },
      onSelected: (String selection) {
        controller.text = selection;
      },
      fieldViewBuilder: (
        context,
        textEditingController,
        focusNode,
        onFieldSubmitted,
      ) {
        return Container(
          decoration: BoxDecoration(
            color: appColors.pink.withOpacity(.5),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            maxLines: maxLines,
            style: appThemes.Medium.copyWith(fontFamily: 'Sans'),
            cursorColor: Colors.white,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: Colors.white60),
              border: InputBorder.none,
              suffixIcon: suffixIcon,
            ),
          ),
        );
      },
    );
  }
}
