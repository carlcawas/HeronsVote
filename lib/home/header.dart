import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart'; 

class CustomHeader extends StatelessWidget {
  final String title;
  final VoidCallback onBack;

  const CustomHeader({
    super.key,
    required this.title,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 24, bottom: 16, top: 26),
      child: Row(
        children: [
          GestureDetector(
            onTap: onBack,
            child: Container(
              height: 40,
              width: 40,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF5C6AA0),
              ),
              child: Padding(
                padding: const EdgeInsets.all(1),
                child: SvgPicture.asset(
                  'assets/back.svg', 
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16), //ayusin ko rin sa figma gawin kong 16
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: Color(0xFF404040),
                fontFamily: 'Geist',
                fontSize: 24,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}