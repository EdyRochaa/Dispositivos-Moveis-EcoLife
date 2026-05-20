import 'package:flutter/material.dart';
import '../models/constants.dart';

class AppBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final icons = [
      Icons.home_outlined,
      Icons.rocket_launch_outlined,
      Icons.add_circle_outline,
      Icons.group_outlined,
      Icons.person_outline,
    ];

    return Container(
      margin: const EdgeInsets.fromLTRB(10, 0, 10, 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: kGreen,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(icons.length, (i) {
          final active = i == currentIndex;
          return GestureDetector(
            onTap: () => onTap(i),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: active ? Colors.white24 : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icons[i],
                color: active ? Colors.white : Colors.white60,
                size: 24,
              ),
            ),
          );
        }),
      ),
    );
  }
}
