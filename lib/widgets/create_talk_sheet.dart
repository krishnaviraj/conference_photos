import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class CreateTalkSheet extends StatefulWidget {
  final Function(String name, String? presenter) onCreateTalk;

  // ignore: use_super_parameters
  const CreateTalkSheet({Key? key, required this.onCreateTalk}) : super(key: key);

  @override
  CreateTalkSheetState createState() => CreateTalkSheetState();
}

class CreateTalkSheetState extends State<CreateTalkSheet> {
  final _nameController = TextEditingController();
  final _presenterController = TextEditingController();
  bool _isNameValid = false;

  @override
  void initState() {
    super.initState();
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
            'Talk details',
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
          ElevatedButton(
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

                    // Then create talk and navigate
                    await widget.onCreateTalk(name, presenter);
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
              'Create talk',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16.0,
              ),
            ),
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