import 'package:flutter/material.dart';
import '../../services/database_service.dart';
import '../../models/baby_profile.dart';

class SelectProfile extends StatefulWidget {
  const SelectProfile({super.key});

  @override
  State<SelectProfile> createState() => _SelectProfileState();
}

class _SelectProfileState extends State<SelectProfile> {
  final DatabaseService _dbService = DatabaseService.instance;
  List<BabyProfile> _profiles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfiles();
  }

  Future<void> _loadProfiles() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final profiles = await _dbService.getAllProfiles();
      setState(() {
        _profiles = profiles;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading profiles: $e');
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading profiles')),
        );
      }
    }
  }

  void _navigateToAddProfile() async {
    await Navigator.pushNamed(context, '/create_profile').then((shouldRefresh){
      if(shouldRefresh == true){
        _loadProfiles();
      }
    });
  }

  void _onProfileTap(BabyProfile profile) {
    Navigator.pushNamed(context, '/home', arguments: profile);
    print('Selected profile: ${profile.fullName}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF6F7F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'My Babies',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
        centerTitle: false,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: Color(0xFF1B86ED)))
          : _profiles.isEmpty
              ? _buildEmptyState()
              : _buildProfileList(),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddProfile,
        backgroundColor: Color(0xFF1B86ED),
        child: Icon(Icons.add, size: 32, color: Colors.white),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Color(0xFFE2EDFF),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.child_care,
                size: 60,
                color: Color(0xFF1B86ED),
              ),
            ),
            SizedBox(height: 32),
            Text(
              'No Baby Profiles Yet',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 12),
            Text(
              'Create your first baby profile to start\nmonitoring their vital signs and wellness',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF8A8A8A),
                height: 1.5,
              ),
            ),
            SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: _navigateToAddProfile,
              icon: Icon(Icons.add, size: 20),
              label: Text('Create First Profile'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF1B86ED),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                textStyle: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileList() {
    return RefreshIndicator(
      onRefresh: _loadProfiles,
      color: Color(0xFF1B86ED),
      child: ListView.builder(
        padding: EdgeInsets.fromLTRB(16, 24, 16, 100),
        itemCount: _profiles.length,
        itemBuilder: (context, index) {
          final profile = _profiles[index];
          return _buildEnhancedProfileCard(profile, index);
        },
      ),
    );
  }

  Widget _buildEnhancedProfileCard(BabyProfile profile, int index) {
    final colors = [
      [Color(0xFFFFE5E5), Color(0xFFFF6B6B)],
      [Color(0xFFE2EDFF), Color(0xFF1B86ED)],
      [Color(0xFFE8F5E9), Color(0xFF4CAF50)],
      [Color(0xFFFFF3E0), Color(0xFFFF9800)],
    ];
    
    final colorSet = colors[index % colors.length];
    final bgColor = colorSet[0];
    final accentColor = colorSet[1];

    return GestureDetector(
      onTap: () => _onProfileTap(profile),
      child: Container(
        margin: EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _onProfileTap(profile),
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with avatar and name
                  Row(
                    children: [
                      // Avatar
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          color: bgColor,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${profile.firstName[0]}${profile.lastName[0]}',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: accentColor,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Baby ${profile.firstName}',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: Colors.black87,
                              ),
                            ),
                            SizedBox(height: 6),
                            Text(
                              profile.lastName,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF8A8A8A),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        color: Color(0xFFC0C0C0),
                        size: 20,
                      ),
                    ],
                  ),

                  SizedBox(height: 16),
                  Divider(color: Color(0xFFF0F0F0), thickness: 1),
                  SizedBox(height: 16),

                  // Info grid
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoChip(
                          icon: Icons.calendar_today,
                          label: 'Age',
                          value: profile.gestationalAge != null 
                              ? '${profile.gestationalAge}w'
                              : '--',
                          color: accentColor,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: _buildInfoChip(
                          icon: Icons.scale,
                          label: 'Weight',
                          value: profile.weight != null 
                              ? '${profile.weight}kg'
                              : '--',
                          color: accentColor,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: _buildInfoChip(
                          icon: Icons.wc,
                          label: 'Gender',
                          value: _formatGender(profile.gender),
                          color: accentColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      decoration: BoxDecoration(
        color: Color(0xFFF6F7F8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
      ),
      child: Column(
        children: [
          Icon(icon, size: 18, color: color),
          SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Color(0xFF8A8A8A),
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: Colors.black87,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  String _formatGender(String? gender) {
    if (gender == null) return '--';
    switch (gender.toLowerCase()) {
      case 'male':
        return '👦';
      case 'female':
        return '👧';
      case 'other':
        return '👶';
      default:
        return '--';
    }
  }
}
