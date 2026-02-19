import 'package:banger_drop/consts/consts.dart';
import 'package:flutter/material.dart';

class CustomDropdown extends StatefulWidget {
  final List<String> items;
  final String selectedItem;
  final void Function(String?) onChanged;

  const CustomDropdown({
    super.key,
    required this.items,
    required this.selectedItem,
    required this.onChanged,
  });

  @override
  State<CustomDropdown> createState() => _CustomDropdownState();
}

class _CustomDropdownState extends State<CustomDropdown> {
  late String currentValue;

  @override
  void initState() {
    super.initState();
    currentValue =
        widget.items.contains(widget.selectedItem)
            ? widget.selectedItem
            : (widget.items.isNotEmpty ? widget.items.first : 'Select');
  }

  @override
  Widget build(BuildContext context) {
    final displayItems = widget.items.isNotEmpty ? widget.items : ['Select'];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
      decoration: BoxDecoration(
        color: Colors.purple.shade700,
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value:
              displayItems.contains(currentValue)
                  ? currentValue
                  : displayItems.first,
          icon: const Icon(Icons.arrow_downward, color: Colors.white),
          dropdownColor: Colors.purple.shade700,
          style: const TextStyle(color: Colors.white, fontSize: 16),
          onChanged:
              widget.items.isNotEmpty
                  ? (value) {
                    if (value != null) {
                      setState(() {
                        currentValue = value;
                      });
                      widget.onChanged(value);
                    }
                  }
                  : null,
          items:
              displayItems.map((String item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: Text(
                    item,
                    style: appThemes.Medium.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              }).toList(),
        ),
      ),
    );
  }
}

class StyledDropdown extends StatelessWidget {
  final List<String> items;
  final String? selectedItem;
  final String hintText;
  final Function(String?) onChanged;

  const StyledDropdown({
    super.key,
    required this.items,
    required this.selectedItem,
    required this.hintText,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.purple,
      ),
      child: DropdownButton<String>(
        value: selectedItem != '' ? selectedItem : null,
        hint: Text(hintText, style: const TextStyle(color: Colors.white)),
        iconEnabledColor: Colors.white,
        dropdownColor: Colors.purple,
        isExpanded: true,
        underline: const SizedBox(),
        style: appThemes.small,
        items:
            items.map((value) {
              return DropdownMenuItem(value: value, child: Text(value));
            }).toList(),
        onChanged: onChanged,
      ),
    );
  }
}
