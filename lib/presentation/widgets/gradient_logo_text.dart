import 'package:flutter/material.dart';

class GradientLogoText extends StatelessWidget {
  final double fontSize;
  const GradientLogoText({super.key, this.fontSize = 36});

  @override
  Widget build(BuildContext context) =>
      Row(mainAxisSize: MainAxisSize.min, children: [
        _part('Mohammed', const [Color(0xFF00CFFF), Color(0xFF4C6FFF)],
            const Color(0x9900CFFF)),
        _part(
            'Store',
            const [Color(0xFFFFC857), Color(0xFFFF6B6B), Color(0xFFFF2D87)],
            const Color(0x99FFB800)),
      ]);

  Widget _part(String text, List<Color> colors, Color glow) => ShaderMask(
        shaderCallback: (bounds) =>
            LinearGradient(colors: colors).createShader(bounds),
        child: Text(text,
            style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: -0.8,
                shadows: [Shadow(color: glow, blurRadius: 18)])),
      );
}
