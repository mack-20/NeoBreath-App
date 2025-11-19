import 'package:flutter/material.dart';
import '../../services/database_service.dart';
import '../../widgets/profile_card.dart';
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
    // Navigate to add profile screen
    final result = await Navigator.pushNamed(context, '/create_profile').then((shouldRefreseh){
      if(shouldRefreseh == true){
        _loadProfiles();
      }
    });
    
    // Reload profiles if a new profile was added
    if (result == true) {
      _loadProfiles();
    }
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
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _profiles.isEmpty
              ? _buildEmptyState()
              : _buildProfileList(),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddProfile,
        backgroundColor: Color(0xFFFF6B6B),
        child: Icon(Icons.add, size: 32, color: Color(0xFFF6F7F8)),
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
            Icon(
              Icons.child_care,
              size: 80,
              color: Colors.grey[400],
            ),
            SizedBox(height: 24),
            Text(
              'No Baby Profiles Yet',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 12),
            Text(
              'Create your first baby profile to start\nmonitoring their health and wellness',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                height: 1.5,
              ),
            ),
            SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _navigateToAddProfile,
              icon: Icon(Icons.add),
              label: Text('Create Profile'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFFF6B6B),
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
            SizedBox(height: 16),
            Text(
              'or tap the + button below',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
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
      child: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: _profiles.length,
        itemBuilder: (context, index) {
          final profile = _profiles[index];
          return ProfileCard(
            profile: profile,
            onTap: () => _onProfileTap(profile),
          );
        },
      ),
    );
  }
}