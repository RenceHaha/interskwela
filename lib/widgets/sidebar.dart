import 'package:flutter/material.dart';
import 'package:interskwela/login_page.dart';
import 'package:interskwela/models/sidebar_menu_item.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Sidebar extends StatefulWidget {
  final List<MenuItem> items;
  final String activeMenu;
  final void Function(String menuName) onMenuSelected;

  const Sidebar({
    super.key,
    required this.items,
    required this.activeMenu,
    required this.onMenuSelected
  });

  @override
  State<Sidebar> createState() => SidebarState();
}

class SidebarState extends State<Sidebar> {


  Future<void> _handleLogout() async {
    // 1. Get the SharedPreferences instance
    final prefs = await SharedPreferences.getInstance();
    
    await prefs.clear(); 

    if (!mounted) return;

    // 3. Navigate to Login Page and remove all previous routes
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
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
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isActive ? const Color(0xFF1C3353) : Colors.transparent,
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

          GestureDetector(
            onTap: () => _handleLogout(),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(8)
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.logout,
                    size: 18,
                    color: Colors.black,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Log out',
                    style: TextStyle(
                      fontSize: 14
                    ),
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}