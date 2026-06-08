import 'package:flutter/material.dart';

class MySlideFadePageTransitionsBuilder extends PageTransitionsBuilder {
  final Duration duration;
  MySlideFadePageTransitionsBuilder(
      {this.duration = const Duration(milliseconds: 300)});

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final offset = Tween<Offset>(begin: const Offset(0.2, 0), end: Offset.zero)
        .chain(CurveTween(curve: Curves.easeOut))
        .animate(animation);
    final opacity = Tween<double>(begin: 0.0, end: 1.0).animate(animation);
    return SlideTransition(
      position: offset,
      child: FadeTransition(opacity: opacity, child: child),
    );
  }
}
