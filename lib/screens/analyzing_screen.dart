import 'package:flutter/material.dart';
import '../utils/constants.dart';

class AnalyzingScreen extends StatefulWidget {
  const AnalyzingScreen({super.key});
  @override
  State<AnalyzingScreen> createState() => _AnalyzingScreenState();
}

class _AnalyzingScreenState extends State<AnalyzingScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      Navigator.of(context).pop(true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.accentBlue,
      body: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: const [
          CircularProgressIndicator(),
          SizedBox(height: 12),
          Text('Analyzing your setup...', style: TextStyle(color: AppColors.subtleText)),
        ]),
      ),
    );
  }
}


