import 'package:flutter/material.dart';

import '../../../models/field.dart';

class FieldInput extends StatelessWidget {
  final TimelineField field;
  final TextEditingController controller;

  const FieldInput({super.key, required this.field, required this.controller});

  @override
  Widget build(BuildContext context) {
    final isNumber = field.type == 'number';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(field.name, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            keyboardType: isNumber
                ? const TextInputType.numberWithOptions(decimal: true)
                : TextInputType.text,
            decoration: InputDecoration(
              hintText: isNumber ? 'Type a number...' : 'Type here...',
            ),
          ),
        ],
      ),
    );
  }
}
