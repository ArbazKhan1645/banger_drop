import 'package:banger_drop/consts/consts.dart';
import 'package:flutter/material.dart';

class DropdownCheckboxSelector extends StatefulWidget {
  final String title;
  final List<String> values;
  final void Function(List<String>) onChanged;

  const DropdownCheckboxSelector({
    Key? key,
    required this.title,
    required this.values,
    required this.onChanged,
  }) : super(key: key);

  @override
  State<DropdownCheckboxSelector> createState() =>
      _DropdownCheckboxSelectorState();
}

class _DropdownCheckboxSelectorState extends State<DropdownCheckboxSelector> {
  bool _isExpanded = false;
  List<String> _selectedValues = [];

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Top Button
        GestureDetector(
          onTap: () => setState(() => _isExpanded = !_isExpanded),
          child: Container(
            decoration: BoxDecoration(
              color: appColors.purple,
              borderRadius: BorderRadius.circular(4),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    letterSpacing: 1.5,
                  ),
                ),
                Icon(
                  _isExpanded ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                  color: Colors.white,
                ),
              ],
            ),
          ),
        ),

        // Dropdown Content
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: Container(
            color: const Color(0xFF800080),
            constraints: const BoxConstraints(maxHeight: 300),
            child: ListView.builder(
              shrinkWrap: true,
              physics: const BouncingScrollPhysics(),
              itemCount: widget.values.length,
              itemBuilder: (context, index) {
                final value = widget.values[index];
                return CheckboxListTile(
                  checkColor: appColors.white,
                  title: Text(
                    value,
                    style: const TextStyle(color: Colors.white),
                  ),
                  activeColor: appColors.purple,
                  value: _selectedValues.contains(value),
                  onChanged: (isChecked) {
                    setState(() {
                      if (isChecked == true) {
                        _selectedValues.add(value);
                      } else {
                        _selectedValues.remove(value);
                      }
                    });
                    widget.onChanged(_selectedValues);
                  },
                );
              },
            ),
          ),
          crossFadeState:
              _isExpanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 200),
        ),
      ],
    );
  }
}
