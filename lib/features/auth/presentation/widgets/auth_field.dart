import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class Authfield extends StatelessWidget {
  final TextEditingController fieldController;
  final FormFieldValidator<String?> validator;
  final String? prefixText;
  final int? maxLength;
  const Authfield({
    super.key,
    required this.fieldController,
    required this.validator,
    this.prefixText,
    required this.maxLength,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      validator: validator,
      controller: fieldController,
      decoration: InputDecoration(
        prefixText: prefixText,
        prefixIcon: const Icon(Icons.phone_outlined),
        hintText: '98XXXXXXXX',
      ),
      keyboardType: TextInputType.number,
      maxLength: maxLength,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
      ],
      buildCounter:
          (
            context, {
            required currentLength,
            required isFocused,
            required maxLength,
          }) => null,
    );
  }
}
