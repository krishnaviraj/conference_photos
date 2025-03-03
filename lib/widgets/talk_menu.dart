// ignore_for_file: use_super_parameters

import 'package:flutter/material.dart';
import '../models/talk.dart';
import '../screens/settings_screen.dart';

class TalkMenu extends StatelessWidget {
  final Talk currentTalk;
  final List<Talk> allTalks;
  final Function(Talk) onTalkSelected;
  final VoidCallback onNewTalk;

  const TalkMenu({
    super.key,
    required this.currentTalk,
    required this.allTalks,
    required this.onTalkSelected,
    required this.onNewTalk,
  });

@override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            child: Center(
              child: Text(
                'Talk to me',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
          ),
          Expanded(
            child: ListView(
              children: [
                // Add Home at the top
                ListTile(
                  leading: const Icon(Icons.home),
                  title: const Text('Home'),
                  onTap: () {
                    Navigator.pop(context); // Close drawer
                    Navigator.of(context).popUntil((route) => route.isFirst); // Go back to first route (home)
                  },
                ),
                const Divider(),
                ...allTalks.map((talk) => ListTile(
                      title: Text(talk.name),
                      selected: talk.id == currentTalk.id,
                      onTap: () {
                        Navigator.pop(context); // First close the drawer
                        if (talk.id != currentTalk.id) {
                          onTalkSelected(talk);
                        }
                      },
                    )),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.add),
                  title: const Text('Start a new talk'),
                  onTap: () {
                    Navigator.pop(context);
                    onNewTalk();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.settings),
                  title: const Text('Settings'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SettingsScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}