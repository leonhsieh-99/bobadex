import 'package:flutter/material.dart';

class StatBox extends StatelessWidget {
  final String label;
  final String value;
  const StatBox({super.key, required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        Text(label, style: TextStyle(color: Colors.grey)),
      ],
    );
  }
}