import 'package:flutter/material.dart';

class DropdownSelector<T> extends StatelessWidget {
  final List<T> items;
  final T? value;
  final String hint;
  final ValueChanged<T?> onChanged;

  const DropdownSelector({
    Key? key,
    required this.items,
    required this.value,
    required this.hint,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      isExpanded: true,
      decoration: InputDecoration(
        border: const OutlineInputBorder(),
        labelText: hint,
      ),
      value: value,
      items: items
          .map((item) => DropdownMenuItem<T>(
                value: item,
                child: Text(
                  item.toString(),
                  style: const TextStyle(color: Colors.black),
                ),
              ))
          .toList(),
      onChanged: onChanged,
      validator: (val) => val == null ? 'Bitte Auswahl treffen' : null,
    );
  }
}
