import 'package:flutter/material.dart';

class CharacterCard extends StatelessWidget {
  final String name;
  final String message;
  final double healthPercent;
  final VoidCallback? onTap;

  const CharacterCard({
    super.key,
    required this.name,
    required this.message,
    required this.healthPercent,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.only(left: 32, right: 32),
          decoration: const BoxDecoration(
            color: Color(0xFFF7D83F),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(8),
              topRight: Radius.circular(8),
            ),
          ),
          child: Text(
            name,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
              fontSize: 16,
              color: Colors.black87,
              letterSpacing: 0.6,
            ),
          ),
        ),
        GestureDetector(
          onTap: onTap,
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                end: Alignment.bottomCenter,
                begin: Alignment.topCenter,
                colors: [Color(0xFFF7D83F), Color(0xFFEFB192)],
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Container(
              padding: const EdgeInsets.only(
                left: 16,
                right: 8,
                bottom: 8,
                top: 16,
              ),
              margin: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(16),
                  topRight: Radius.circular(32),
                  topLeft: Radius.circular(16),
                ),
                color: Colors.white,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withAlpha((0.98 * 255).round()),
                    Colors.grey.shade50,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha((0.12 * 255).round()),
                    offset: const Offset(0, 8),
                    blurRadius: 18,
                  ),
                  BoxShadow(
                    color: Colors.black.withAlpha((0.06 * 255).round()),
                    offset: const Offset(0, 4),
                    blurRadius: 8,
                  ),
                  BoxShadow(
                    color: Colors.white.withAlpha((0.9 * 255).round()),
                    offset: const Offset(0, -2),
                    blurRadius: 6,
                    spreadRadius: -4,
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      message,
                      textAlign: TextAlign.left,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: 16,
                        color: Colors.black87,
                        fontStyle: FontStyle.italic,
                        height: 1.35,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                  Container(
                    alignment: Alignment.centerRight,
                    child: Image.asset(
                      'assets/instagram.png',
                      width: 32,
                      height: 32,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
