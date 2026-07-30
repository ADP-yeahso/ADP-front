import 'package:flutter/material.dart';

class GalleryScreen extends StatelessWidget {
  const GalleryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('갤러리'),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Text('갤러리 화면'),
      ),
    );
  }
}