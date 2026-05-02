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
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: MediaQuery.of(context).padding.top,
          color: Colors.white,
        ),
        
        Container(
          width: double.infinity,
          padding: const EdgeInsets.only(left: 24, bottom: 16, top: 24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.white.withOpacity(1.0), 
                Colors.white.withOpacity(0.8),
                Colors.white.withOpacity(0.0), 
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
          child: Row(
            children: [
              // Back Button
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
              
              const SizedBox(width: 16),
              
              SizedBox(
                width: 250,
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF404040),
                    fontFamily: 'Geist',
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
