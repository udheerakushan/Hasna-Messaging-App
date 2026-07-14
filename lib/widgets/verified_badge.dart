import 'package:flutter/material.dart';

class VerifiedBadge extends StatelessWidget {
  const VerifiedBadge({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: Colors.green[600], borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [Icon(Icons.check, size: 12, color: Colors.white), SizedBox(width: 4), Text('Official', style: TextStyle(color: Colors.white, fontSize: 12))],
      ),
    );
  }
}
