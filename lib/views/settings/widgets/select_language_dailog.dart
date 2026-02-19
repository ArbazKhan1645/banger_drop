import 'package:banger_drop/consts/consts.dart';
import 'package:flutter/material.dart';

class LanguageDialog extends StatelessWidget {
  final List<String> languages = ['English', 'Spanish', 'French', 'German'];
  final String selectedLanguage;
  final Function(String) onLanguageSelected;

  LanguageDialog({
    Key? key,
    required this.selectedLanguage,
    required this.onLanguageSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: appColors.purple,
      title: Text('Select Language', style: appThemes.Large),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: languages.length,
          itemBuilder: (context, index) {
            final language = languages[index];
            final isSelected = language == selectedLanguage;

            return ListTile(
              title: Text(
                language,
                style: appThemes.Medium.copyWith(fontFamily: 'Sans'),
              ),
              trailing:
                  isSelected
                      ? Icon(Icons.arrow_left_outlined, color: appColors.white)
                      : null,
              onTap: () {
                onLanguageSelected(language);
                Navigator.of(context).pop();
              },
            );
          },
        ),
      ),
    );
  }
}
