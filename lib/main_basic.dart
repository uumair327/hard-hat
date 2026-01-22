import 'package:flutter/material.dart';

void main() {
  print('Starting basic Flutter app...');
  runApp(const BasicApp());
}

class BasicApp extends StatelessWidget {
  const BasicApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Basic Flutter App',
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Basic Flutter App'),
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Flutter is working!',
                style: TextStyle(fontSize: 24),
              ),
              SizedBox(height: 20),
              Text(
                'This is a basic Flutter app without any custom dependencies.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}