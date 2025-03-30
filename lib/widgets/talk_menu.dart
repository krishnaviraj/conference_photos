// ignore_for_file: use_super_parameters

import 'package:flutter/material.dart';
import '../models/talk.dart';
import '../screens/settings_screen.dart';
import '../theme/app_theme.dart';
import '../services/storage_service.dart';

class TalkMenu extends StatelessWidget {
  final Talk currentTalk;
  final List<Talk> allTalks;
  final Function(Talk) onTalkSelected;
  final VoidCallback onNewTalk;
  final StorageService storageService;

  const TalkMenu({
    super.key,
    required this.currentTalk,
    required this.allTalks,
    required this.onTalkSelected,
    required this.onNewTalk,
    required this.storageService,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFF171F36), // Dark navy background
      child: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.teal,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Talk to me',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  // Add Home at the top
                  ListTile(
                    leading: const Icon(Icons.home, color: Colors.white),
                    title: const Text(
                      'Home',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context); // Close drawer
                      Navigator.of(context).popUntil((route) => route.isFirst); // Go back to first route (home)
                    },
                  ),
                  const Divider(
                    color: Colors.white24,
                    height: 1,
                    indent: 16,
                    endIndent: 16,
                  ),
                  ...allTalks.map((talk) => _buildTalkItem(context, talk)),
                  const Divider(
                    color: Colors.white24,
                    height: 1,
                    indent: 16,
                    endIndent: 16,
                  ),
                  ListTile(
                    leading: const Icon(
                      Icons.add,
                      color: AppTheme.accentColor,
                    ),
                    title: const Text(
                      'Start a new group',
                      style: TextStyle(
                        color: AppTheme.accentColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      onNewTalk();
                    },
                  ),
                ],
              ),
            ),
            const Divider(
              color: Colors.white24,
              height: 1,
            ),
            ListTile(
              leading: const Icon(
                Icons.settings,
                color: Colors.white70,
              ),
              title: const Text(
                'Settings',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SettingsScreen(storageService: storageService),
                    ),
                  );
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildTalkItem(BuildContext context, Talk talk) {
    final isSelected = talk.id == currentTalk.id;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected ? AppTheme.accentColor.withAlpha(25) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        title: Text(
          talk.name,
          style: TextStyle(
            color: isSelected ? AppTheme.accentColor : Colors.white,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 16,
          ),
        ),
        selected: isSelected,
        onTap: () {
          Navigator.pop(context); // First close the drawer
          if (talk.id != currentTalk.id) {
            onTalkSelected(talk);
          }
        },
      ),
    );
  }
}