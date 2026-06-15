import 'package:flutter/material.dart';

/// Sporta logo image. [white] renders the white-tinted variant used on
/// dark gradient backgrounds.
class SportaLogo extends StatelessWidget {
  const SportaLogo({super.key, this.width = 120, this.white = false});

  final double width;
  final bool white;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/logo.png',
      width: width,
      color: white ? Colors.white : null,
    );
  }
}
