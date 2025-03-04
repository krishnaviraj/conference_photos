import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/talk.dart';

class EditTalkSheet extends StatefulWidget {
  final Talk talk;
  final Function(String name, String? presenter) onUpdateTalk;

  const EditTalkSheet({
    Key? key, 
    required this.talk,
    required this.onUpdateTalk,
  }) : super(key: key);

  @override
  EditTalkSheetState createState() => EditTalkSheetState();
}

class EditTalkSheetState extends State<EditTalkSheet> {
  late TextEditingController _nameController;
  late TextEditingController _presenterController;
  bool _isNameValid = true;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.talk.name);
    _presenterController = TextEditingController(text: widget.talk.presenter ?? '');
    _nameController.addListener(_validateName);
  }

  void _validateName() {
    setState(() {
      _isNameValid = _nameController.text.trim().isNotEmpty;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16.0,
        right: 16.0,
        top: 24.0,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24.0),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Edit talk details',
            style: TextStyle(
              color: Colors.black87,
              fontSize: 24,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24.0),
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'Talk name',
              labelStyle: const TextStyle(color: Colors.black54),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade500),
              ),
              contentPadding: const EdgeInsets.all(16),
            ),
            style: const TextStyle(color: Colors.black87),
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: 16.0),
          TextField(
            controller: _presenterController,
            decoration: InputDecoration(
              labelText: "Who's talking?",
              labelStyle: const TextStyle(color: Colors.black54),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade500),
              ),
              contentPadding: const EdgeInsets.all(16),
            ),
            style: const TextStyle(color: Colors.black87),
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 32.0),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.black54,
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(width: 16.0),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isNameValid
                      ? () async {
                          final name = _nameController.text.trim();
                          final presenter = _presenterController.text.trim().isEmpty
                              ? null
                              : _presenterController.text.trim();

                          // Close sheet first
                          if (mounted) {
                            Navigator.pop(context);
                          }

                          // Then update talk
                          await widget.onUpdateTalk(name, presenter);
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentColor,
                    foregroundColor: AppTheme.primaryColor,
                    disabledBackgroundColor: AppTheme.accentColor.withAlpha(128),
                    disabledForegroundColor: AppTheme.primaryColor.withAlpha(128),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28.0),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                  ),
                  child: const Text(
                    'Update',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16.0,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16.0),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _presenterController.dispose();
    super.dispose();
  }
}