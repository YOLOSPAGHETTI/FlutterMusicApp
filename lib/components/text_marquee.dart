import 'package:flutter/material.dart';
import 'package:marquee/marquee.dart';

class TextMarquee extends StatelessWidget {
  final String text;
  final TextStyle style;
  final double maxWidth;
  const TextMarquee(
      {super.key,
      required this.text,
      required this.style,
      required this.maxWidth});

  @override
  Widget build(BuildContext context) {
    // Measure the width of the text
    final textPainter = TextPainter(
      text: TextSpan(text: text, style: style),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: maxWidth); // Use the provided maxWidth

    // Check if the text overflows
    final bool isOverflowing = textPainter.didExceedMaxLines;

    if (isOverflowing) {
      // Apply marquee effect if overflow detected
      return SizedBox(
        height: 25, // Set a fixed height for the marquee
        width: maxWidth, // Constrain the marquee width
        child: Marquee(
          text: text,
          style: style,
          scrollAxis: Axis.horizontal,
          blankSpace: 20.0,
          velocity: 50.0,
          pauseAfterRound: Duration(seconds: 1),
          startPadding: 10.0,
          //accelerationDuration: Duration(seconds: 1),
          //accelerationCurve: Curves.linear,
          //decelerationDuration: Duration(milliseconds: 500),
          //decelerationCurve: Curves.easeOut,
        ),
      );
    }

    // Otherwise, show the static text
    return SizedBox(
      height: 25,
      width: maxWidth, // Constrain the static text width
      child: Text(
        text,
        style: style,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
