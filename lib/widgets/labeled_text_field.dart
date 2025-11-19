import 'package:flutter/material.dart';

class LabeledTextField extends StatelessWidget {
  final IconData icon;
  final String label;
  final String hint;
  final TextInputType textInputType;
  final TextEditingController controller;

  const LabeledTextField({
    super.key,
    required this.icon,
    required this.label,
    required this.hint,
    required this.textInputType,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label),
          const SizedBox(height: 5),
          TextFormField(
            controller: controller,
            keyboardType: textInputType,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return "Please enter a valid $label";
              } else if (label == "Gestational Age (weeks)") {
                final gestationalAge = int.parse(controller.text);
                if (gestationalAge <= 40 && gestationalAge >= 20) {
                  return null;
                } else {
                  return "Invalid gestational age entered";
                }
              } else if (label == "Birth Weight") {
                final birthWeight = double.parse(controller.text);
                if (birthWeight <= 10.0 && birthWeight >= 1.0) {
                  return null;
                } else {
                  return "Invalid birth weight entered";
                }
              }
              return null;
            },
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: Color(0xFFA0A0A9)),
              hintText: hint,
              hintStyle: const TextStyle(color: Color(0xFFA0A0A9)),
              border: const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(17.0)),
              ),
            ),
          ),
          const SizedBox(height: 4.0),
        ],
      ),
    );
  }
}
