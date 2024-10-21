import 'package:flutter/material.dart';

class MojiColorFiltered extends StatefulWidget {
  const MojiColorFiltered({required this.darkness, required this.child, super.key});
  final bool darkness;
  final Widget child;

  @override
  State<MojiColorFiltered> createState() => _MojiColorFilteredState();
}

const darkFilter = ColorFilter.matrix(
  [
    -1, 0, 0, 0, 255, // Red
    0, -1, 0, 0, 255, // Green
    0, 0, -1, 0, 255, // Blue
    0, 0, 0, 1, 0 // Alpha
  ],
);

const brightFilter = ColorFilter.matrix(
  [
    1, 0, 0, 0, 0, // Red
    0, 1, 0, 0, 0, // Green
    0, 0, 1, 0, 0, // Blue
    0, 0, 0, 1, 0, // Alpha
  ],
);

class _MojiColorFilteredState extends State<MojiColorFiltered> {
  @override
  Widget build(BuildContext context) {
    return ColorFiltered(
      colorFilter: widget.darkness ? darkFilter : brightFilter,
      child: widget.child,
    );
  }
}
