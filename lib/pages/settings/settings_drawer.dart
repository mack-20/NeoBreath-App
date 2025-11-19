import 'package:flutter/material.dart';
import '../../models/baby_profile.dart';
import 'view_history.dart';
import 'view_profile.dart';

class SettingsDrawer extends StatefulWidget {
  final BabyProfile profile;

  const SettingsDrawer({
    super.key,
    required this.profile,
  });

  @override
  State<SettingsDrawer> createState() => _SettingsDrawerState();
}

class _SettingsDrawerState extends State<SettingsDrawer> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: SizedBox(
        width: MediaQuery.of(context).size.width * 0.9,
        child: Material(
          color: Colors.white,
          child: Column(
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: EdgeInsets.fromLTRB(20, 16, 20, 20),
                decoration: BoxDecoration(
                  color: Color(0xFF1B86ED),
                  borderRadius: BorderRadius.only(
                    bottomRight: Radius.circular(24),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Settings',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(Icons.close, color: Colors.white, size: 28),
                          padding: EdgeInsets.zero,
                          constraints: BoxConstraints(),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Baby ${widget.profile.firstName}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),

              // Menu Items
              Expanded(
                child: ListView(
                  padding: EdgeInsets.fromLTRB(0, 8, 0, 20),
                  children: [
                    _buildMenuItem(
                      index: 0,
                      icon: Icons.history,
                      label: 'View History',
                      onTap: () {
                        setState(() => _selectedIndex = 0);
                      },
                    ),
                    _buildMenuItem(
                      index: 1,
                      icon: Icons.person,
                      label: 'View Profile',
                      onTap: () {
                        setState(() => _selectedIndex = 1);
                      },
                    ),
                  ],
                ),
              ),

              // Content Area
              Expanded(
                flex: 3,
                child: _buildContent(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required int index,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final isSelected = _selectedIndex == index;
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? Color(0xFF1B86ED) : Color(0xFF8A8A8A),
        size: 24,
      ),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 16,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          color: isSelected ? Color(0xFF1B86ED) : Colors.black87,
        ),
      ),
      trailing: isSelected
          ? Container(
              width: 4,
              height: 24,
              decoration: BoxDecoration(
                color: Color(0xFF1B86ED),
                borderRadius: BorderRadius.circular(2),
              ),
            )
          : null,
      onTap: onTap,
      contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
    );
  }

  Widget _buildContent() {
    switch (_selectedIndex) {
      case 0:
        return ViewHistory(profile: widget.profile);
      case 1:
        return ViewProfile(profile: widget.profile);
      default:
        return SizedBox.shrink();
    }
  }
}
