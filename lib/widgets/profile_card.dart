import 'package:flutter/material.dart';
import 'profile_avatar.dart';
import '../models/baby_profile.dart';

class ProfileCard extends StatelessWidget {
  final BabyProfile profile;
  final VoidCallback onTap;

  const ProfileCard({
    super.key,
    required this.profile,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      margin: EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Avatar with initials
                  ProfileAvatar(
                    firstName: profile.firstName,
                    lastName: profile.lastName,
                    size: 60,
                  ),
                  SizedBox(width: 16),
                  // Name and gestational age
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Baby ${profile.firstName}',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        SizedBox(height: 4),
                        if (profile.gestationalAge != null)
                          Text(
                            'Gestational Age: ${profile.gestationalAge} Weeks',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF8A8A8A),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              // SpO2 section - placeholder for now
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Color(0xFFF6F7F8),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Avg. SpO2',
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFF48576B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '--', // Placeholder - will be dynamic later
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF48576B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}