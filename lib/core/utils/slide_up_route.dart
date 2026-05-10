import 'package:flutter/material.dart';

class SlideUpRoute extends PageRouteBuilder {
  final Widget page;

  SlideUpRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          // Tweak this duration if you want it faster or slower
          transitionDuration: const Duration(milliseconds: 400), 
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            
            // X: 0.0 (No horizontal movement)
            // Y: 1.0 (Start exactly 1 full screen height below the bottom)
            const begin = Offset(0.0, 1.0); 
            const end = Offset.zero; // End at the normal position
            
            // easeOutCubic gives it that premium "fast start, slow stop" feel
            const curve = Curves.easeOutCubic; 

            var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );
          },
        );
}