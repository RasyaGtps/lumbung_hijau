import 'package:flutter/material.dart';

class AdminBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const AdminBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.home_outlined, Icons.home, 0),
              _buildNavItem(Icons.event_note_outlined, Icons.event_note, 1),
              _buildNavItem(Icons.person_add_outlined, Icons.person_add, 2),
              _buildNavItem(Icons.history_outlined, Icons.history, 3),
              _buildNavItem(Icons.person_outline, Icons.person, 4),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData inactiveIcon, IconData activeIcon, int index) {
    final isActive = currentIndex == index;
    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        child: Icon(
          isActive ? activeIcon : inactiveIcon,
          color: isActive ? const Color(0xFFF86812) : Colors.grey[400],
          size: 28,
        ),
      ),
    );
  }
}
