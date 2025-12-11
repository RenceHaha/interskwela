import 'package:flutter/material.dart';
import 'package:interskwela/models/sidebar_menu_item.dart';
import 'package:interskwela/screens/profile_screen.dart';
import 'package:interskwela/widgets/change_password_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Sidebar extends StatefulWidget {
  final List<MenuItem> items;
  final String activeMenu;
  final void Function(String menuName) onMenuSelected;

  const Sidebar({
    super.key,
    required this.items,
    required this.activeMenu,
    required this.onMenuSelected,
  });

  @override
  State<Sidebar> createState() => SidebarState();
}

class SidebarState extends State<Sidebar> {
  int? _userId;

  @override
  void initState() {
    super.initState();
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userId = prefs.getInt('userId');
    });
  }

  Future<void> _handleLogout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    if (!mounted) return;

    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
  }

  void _navigateToProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ProfileScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<MenuItem> items = widget.items;

    return Container(
      width: 240,
      color: Colors.white,
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  ...items.map((item) {
                    final isActive = widget.activeMenu == item.label;
                    return GestureDetector(
                      onTap: () => widget.onMenuSelected(item.label),
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isActive
                              ? const Color(0xFF1C3353)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              item.icon,
                              size: 18,
                              color: isActive ? Colors.white : Colors.black,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              item.label,
                              style: TextStyle(
                                color: isActive ? Colors.white : Colors.black,
                                fontSize: 14,
                                fontFamily: 'Inter',
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),

          // Profile Button
          _buildBottomButton(
            icon: Icons.person_outline,
            label: 'Profile',
            onTap: _navigateToProfile,
          ),

          // Logout Button
          _buildBottomButton(
            icon: Icons.logout,
            label: 'Log out',
            onTap: _handleLogout,
          ),

          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildBottomButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: Colors.black),
            const SizedBox(width: 12),
            Text(label, style: const TextStyle(fontSize: 14)),
          ],
        ),
      ),
    );
  }
}
