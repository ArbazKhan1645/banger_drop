import 'package:banger_drop/consts/consts.dart';
import 'package:flutter/material.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ProfileField extends StatelessWidget {
  final String title;
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;
  final active;

  const ProfileField({
    super.key,
    required this.title,
    required this.controller,
    this.onChanged,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$title :',
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.purpleAccent, width: 1.5),
            borderRadius: BorderRadius.circular(8),
            color: Colors.transparent,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: TextField(
            enabled: active ?? false,
            controller: controller,
            onChanged: onChanged, // 👈 Pass the callback here
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: const InputDecoration(
              border: InputBorder.none,
              hintText: '',
              hintStyle: TextStyle(color: Colors.grey),
            ),
          ),
        ),
      ],
    );
  }
}

class DateProfileField extends StatelessWidget {
  final String title;
  final TextEditingController controller;
  final bool active;
  final VoidCallback? onChanged;

  const DateProfileField({
    super.key,
    required this.title,
    required this.controller,
    required this.active,
    this.onChanged,
  });

  Future<void> _selectDate(BuildContext context) async {
    final DateTime now = DateTime.now();
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(1900),
      lastDate: now,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.purpleAccent,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      final formattedDate = DateFormat('yyyy-MM-dd').format(pickedDate);
      controller.text = formattedDate;
      onChanged?.call(); // 👈 Notifies parent
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$title :',
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: active ? () => _selectDate(context) : null,
          child: AbsorbPointer(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.purpleAccent, width: 1.5),
                borderRadius: BorderRadius.circular(8),
                color: Colors.transparent,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: TextField(
                controller: controller,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Select date',
                  hintStyle: const TextStyle(color: Colors.grey),
                  suffixIcon:
                      active
                          ? const Icon(
                            Icons.calendar_today,
                            color: Colors.white,
                          )
                          : null,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 14,
                  ), // 👈 Add this line
                ),
                readOnly: true,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class CountryProfileField extends StatelessWidget {
  final String title;
  final TextEditingController controller;
  final bool active;
  final Function(String)? onChanged;

  const CountryProfileField({
    Key? key,
    required this.title,
    required this.controller,
    this.active = true,
    this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: active ? Colors.white : Colors.grey,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: active ? Colors.white24 : Colors.white12,
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: controller.text.isNotEmpty ? controller.text : null,
              isExpanded: true,
              dropdownColor: appColors.purple,
              iconEnabledColor: active ? Colors.white : Colors.grey,
              items:
                  _countryList.map((country) {
                    return DropdownMenuItem<String>(
                      value: country,
                      child: Text(
                        country,
                        style: TextStyle(color: Colors.white),
                      ),
                    );
                  }).toList(),
              onChanged:
                  active
                      ? (newValue) {
                        if (newValue != null) {
                          controller.text = newValue;
                          onChanged?.call(newValue);
                        }
                      }
                      : null,

              hint: Text(
                'Select Country',
                style: TextStyle(color: Colors.white70),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// Example country list
const List<String> _countryList = [
  'Pakistan',
  'United States',
  'United Kingdom',
  'Canada',
  'Australia',
  'India',
  // add more as needed
];
