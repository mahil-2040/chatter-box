import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      
      body: Center(
        child: SpinKitWaveSpinner(
          color: Colors.white,
          size: 50.0,
        ),
      ),
    );
  }
}
