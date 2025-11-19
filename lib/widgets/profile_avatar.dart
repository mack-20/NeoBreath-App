import 'package:flutter/material.dart';

class ProfileAvatar extends StatelessWidget {
  final String firstName;
  final String lastName;
  final double size;

  const ProfileAvatar({
    super.key,
    required this.firstName,
    required this.lastName,
    this.size = 60,
  });

  // Generate initials from first and last name
  String _getInitials() {
    final firstInitial = firstName.isNotEmpty ? firstName[0].toUpperCase() : '';
    final lastInitial = lastName.isNotEmpty ? lastName[0].toUpperCase() : '';
    return '$firstInitial$lastInitial';
  }

  // Generate a consistent color based on the name
  Color _generateColor() {
    // Create a hash from the name
    final String name = firstName + lastName;
    int hash = 0;
    for (int i = 0; i < name.length; i++) {
      hash = name.codeUnitAt(i) + ((hash << 5) - hash);
    }

    // Predefined set of pleasant pastel colors for baby profiles
    final List<Color> colors = [
      Color(0xFFFFB5A7), // Peach
      Color(0xFFFEC8D8), // Pink
      Color(0xFFD4A5A5), // Mauve
      Color(0xFFB5DEFF), // Light Blue
      Color(0xFFA8E6CF), // Mint Green
      Color(0xFFFFD3B6), // Apricot
      Color(0xFFD4C5F9), // Lavender
      Color(0xFFFFE156), // Soft Yellow
      Color(0xFFC7CEEA), // Periwinkle
      Color(0xFFFFDAB9), // Peach Puff
      Color(0xFFE0BBE4), // Lilac
      Color(0xFFB4D7D8), // Powder Blue
      Color(0xFFFDE2E4), // Baby Pink
      Color(0xFFFFD6A5), // Peach
      Color(0xFFCAFFBF), // Mint
    ];

    // Use hash to pick a color
    final index = hash.abs() % colors.length;
    return colors[index];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: _generateColor(),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          _getInitials(),
          style: TextStyle(
            fontSize: size * 0.4, // Scale font size with avatar size
            fontWeight: FontWeight.w600,
            color: Colors.white,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }
}

// Optional: Extended version with custom color option
class ProfileAvatarCustom extends StatelessWidget {
  final String firstName;
  final String lastName;
  final double size;
  final Color? backgroundColor;
  final Color? textColor;

  const ProfileAvatarCustom({
    super.key,
    required this.firstName,
    required this.lastName,
    this.size = 60,
    this.backgroundColor,
    this.textColor,
  });

  String _getInitials() {
    final firstInitial = firstName.isNotEmpty ? firstName[0].toUpperCase() : '';
    final lastInitial = lastName.isNotEmpty ? lastName[0].toUpperCase() : '';
    return '$firstInitial$lastInitial';
  }

  Color _generateColor() {
    final String name = firstName + lastName;
    int hash = 0;
    for (int i = 0; i < name.length; i++) {
      hash = name.codeUnitAt(i) + ((hash << 5) - hash);
    }

    final List<Color> colors = [
      Color(0xFFFFB5A7), Color(0xFFFEC8D8), Color(0xFFD4A5A5),
      Color(0xFFB5DEFF), Color(0xFFA8E6CF), Color(0xFFFFD3B6),
      Color(0xFFD4C5F9), Color(0xFFFFE156), Color(0xFFC7CEEA),
      Color(0xFFFFDAB9), Color(0xFFE0BBE4), Color(0xFFB4D7D8),
      Color(0xFFFDE2E4), Color(0xFFFFD6A5), Color(0xFFCAFFBF),
    ];

    final index = hash.abs() % colors.length;
    return colors[index];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor ?? _generateColor(),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          _getInitials(),
          style: TextStyle(
            fontSize: size * 0.4,
            fontWeight: FontWeight.w600,
            color: textColor ?? Colors.white,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }
}