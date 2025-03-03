import 'package:flutter/material.dart';

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
        top: 16.0,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Talk details',
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24.0),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Talk name',
              border: OutlineInputBorder(),
            ),
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: 16.0),
          TextField(
            controller: _presenterController,
            decoration: const InputDecoration(
              labelText: "Who's talking?",
              border: OutlineInputBorder(),
            ),
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 24.0),
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
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 12.0),
              child: Text('Create talk'),
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