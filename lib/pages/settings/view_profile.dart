import 'package:flutter/material.dart';
import '../../models/baby_profile.dart';

class ViewProfile extends StatelessWidget {
  final BabyProfile profile;

  const ViewProfile({
    super.key,
    required this.profile,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Baby Name Section
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Color(0xFFF6F7F8),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Color(0xFF1B86ED), width: 2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Baby\'s Name',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF8A8A8A),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '${profile.firstName} ${profile.lastName}',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1B86ED),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 24),

            // Profile Details Grid
            Text(
              'Profile Information',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 12),

            // Gestational Age
            _buildProfileCard(
              icon: Icons.calendar_today,
              label: 'Gestational Age',
              value: profile.gestationalAge != null ? '${profile.gestationalAge} weeks' : 'Not set',
              color: Color(0xFF1B86ED),
              bgColor: Color(0xFFE2EDFF),
            ),

            SizedBox(height: 12),

            // Weight
            _buildProfileCard(
              icon: Icons.scale,
              label: 'Weight',
              value: profile.weight != null ? '${profile.weight} kg' : 'Not set',
              color: Color(0xFF4CAF50),
              bgColor: Color(0xFFE8F5E9),
            ),

            SizedBox(height: 12),

            // Gender
            _buildProfileCard(
              icon: Icons.wc,
              label: 'Gender',
              value: _formatGender(profile.gender),
              color: Color(0xFFFF6B6B),
              bgColor: Color(0xFFFFE5E5),
            ),

            SizedBox(height: 12),

            // Created Date
            _buildProfileCard(
              icon: Icons.info,
              label: 'Profile Created',
              value: _formatDate(profile.createdAt),
              color: Color(0xFF8A8A8A),
              bgColor: Color(0xFFF0F0F0),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xFFF0F0F0), width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: bgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF8A8A8A),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatGender(String? gender) {
    if (gender == null) return 'Not set';
    switch (gender.toLowerCase()) {
      case 'male':
        return '👦 Male';
      case 'female':
        return '👧 Female';
      case 'other':
        return '👶 Other';
      default:
        return gender;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
