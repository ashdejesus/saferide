import 'package:flutter/material.dart';

class M3SeverityLabel extends StatelessWidget {
  const M3SeverityLabel({super.key, required this.severity});
  final int severity;

  @override
  Widget build(BuildContext context) {
    final Color color;
    final String label;
    switch (severity) {
      case 5: color = Colors.red;                   label = 'Critical'; break;
      case 4: color = Colors.orange;                label = 'High';     break;
      case 3: color = Colors.amber.shade700;        label = 'Moderate'; break;
      case 2: color = Colors.lightGreen.shade600;   label = 'Low';      break;
      default: color = Colors.green;               label = 'Minimal';  break;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label, 
        style: TextStyle(
          fontSize: 12, 
          fontWeight: FontWeight.bold, 
          color: color,
        ),
      ),
    );
  }
}
