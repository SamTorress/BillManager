import 'package:flutter/material.dart';
import 'screens/bill_list_screen.dart';

void main() {
  runApp(const BillApp());
}

class BillApp extends StatelessWidget {
  const BillApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bill Manager',
      theme: ThemeData(colorSchemeSeed: Colors.teal, useMaterial3: true),
      home: const BillListScreen(),
    );
  }
}
