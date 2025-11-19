import 'package:flutter/material.dart';

class build_status_card extends StatelessWidget {
  const build_status_card({
    super.key,
    required this.context,
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
    required this.title,
    required this.value,
    required this.unit,
  });

  final BuildContext context;
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;
  final String title;
  final String value;
  final String unit;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.90,
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: iconBgColor,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: iconColor, size: 22),
                  ),
                  SizedBox(width: 12),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF48576B),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(width: 8),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6.0),
                    child: Text(
                      unit,
                      style: TextStyle(
                        color: Color(0xFF48576B),
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}