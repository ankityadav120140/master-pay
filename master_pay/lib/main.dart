// ignore_for_file: prefer_is_empty, library_private_types_in_public_api, sized_box_for_whitespace, avoid_print

import 'package:flutter/material.dart';

import 'page/home.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'UPI Master',
      home: HomePage(),
    );
  }
}
