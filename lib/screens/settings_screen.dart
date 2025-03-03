import 'package:flutter/material.dart';
import '../services/date_format_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _selectedDateFormat = DateFormatService.getCurrentFormat();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          ListTile(
            title: const Text('Date Format'),
            subtitle: Text(_selectedDateFormat),
            onTap: _showDateFormatOptions,
          ),
          // Add more settings as needed
        ],
      ),
    );
  }

  void _showDateFormatOptions() {
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Choose Date Format'),
        children: [
          SimpleDialogOption(
            onPressed: () async {
              await DateFormatService.setFormat(DateFormatService.FORMAT_MMDDYYYY);
              setState(() {
                _selectedDateFormat = DateFormatService.FORMAT_MMDDYYYY;
              });
              Navigator.pop(context);
            },
            child: const Text('MM/DD/YYYY'),
          ),
          SimpleDialogOption(
            onPressed: () async {
              await DateFormatService.setFormat(DateFormatService.FORMAT_DDMMYYYY);
              setState(() {
                _selectedDateFormat = DateFormatService.FORMAT_DDMMYYYY;
              });
              Navigator.pop(context);
            },
            child: const Text('DD/MM/YYYY'),
          ),
        ],
      ),
    );
  }
}