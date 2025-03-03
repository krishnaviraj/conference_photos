// ignore_for_file: use_super_parameters, use_build_context_synchronously

import 'package:flutter/material.dart';
import '../models/talk.dart';
import '../widgets/empty_state_tile.dart';
import '../widgets/talk_card.dart';
import '../widgets/create_talk_sheet.dart';
import '../widgets/confirmation_dialog.dart';
import '../widgets/contextual_app_bar.dart';
import '../screens/talk_view_screen.dart';
import '../services/storage_service.dart';
import '../mixins/undo_operation_mixin.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_fab.dart';
import '../utils/page_transitions.dart';

class HomeScreen extends StatefulWidget {
  final StorageService storageService;

  const HomeScreen({
    Key? key,
    required this.storageService,
  }) : super(key: key);

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> with UndoOperationMixin {
  List<Talk> talks = [];
  Map<String, Talk> _pendingDeletions = {}; // Track talks by their IDs
  Set<String> _selectedTalks = {};
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _loadTalks();
  }

  Future<void> _loadTalks() async {
    final loadedTalks = await widget.storageService.loadTalks();
    setState(() {
      talks = loadedTalks;
    });
  }

  void _showCreateTalkSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) => CreateTalkSheet(
        onCreateTalk: (name, presenter) async {
          // Create the talk
          final talk = Talk(
            id: DateTime.now().toString(),
            name: name,
            presenter: presenter,
            createdAt: DateTime.now(),
          );

          // Update local state and storage
          setState(() {
            talks.add(talk);
          });
          await widget.storageService.saveTalks(talks);

          if (!mounted) return;

          // Use the same navigation method we use for existing talks
          _navigateToTalkView(talk);
        },
      ),
    );
  }

  void _navigateToTalkView(Talk talk) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TalkViewScreen(
          talk: talk,
          allTalks: talks,
          onTalkSelected: _navigateToTalkView,
          onNewTalk: _showCreateTalkSheet,
          storageService: widget.storageService,
        ),
      ),
    ).then((_) {
      // Reload talks when returning from TalkViewScreen
      if (mounted) {
        _loadTalks();
      }
    });
  }

  void _handleTalkLongPress(String talkId) {
    setState(() {
      if (_selectedTalks.contains(talkId)) {
        _selectedTalks.remove(talkId);
      } else {
        _selectedTalks.add(talkId);
      }
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedTalks.clear();
    });
  }

  void _deleteSelectedTalks() {
    showDialog(
      context: context,
      builder: (context) => ConfirmationDialog(
        title: 'Delete Talks',
        message: 'Are you sure you want to delete ${_selectedTalks.length} talks? This cannot be undone.',
        onConfirm: () async {
          final talksToDelete = talks.where((t) => _selectedTalks.contains(t.id)).toList();
          setState(() {
            talks.removeWhere((t) => _selectedTalks.contains(t.id));
            _selectedTalks.clear();
          });

          for (final talk in talksToDelete) {
            await widget.storageService.deleteTalk(talk.id);
          }
        },
      ),
    );
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchController.clear();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: AppTheme.primaryGradient,
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: _selectedTalks.isEmpty
            ? AppBar(
                title: _isSearching
                    ? TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search for something...',
                          hintStyle: TextStyle(color: Colors.white.withAlpha(179)),
                          border: InputBorder.none,
                        ),
                        style: const TextStyle(color: Colors.white),
                        autofocus: true,
                      )
                    : Row(
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
                          const Text(
                            'Talk to me',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                backgroundColor: Colors.transparent,
                elevation: 0,
                actions: [
                  if (talks.isNotEmpty && !_isSearching)
                    IconButton(
                      icon: const Icon(Icons.search),
                      onPressed: _toggleSearch,
                    ),
                  if (_isSearching)
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: _toggleSearch,
                    ),
                  if (!_isSearching && talks.isNotEmpty)
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert),
                      onSelected: (value) async {
                        if (value == 'clear_data') {
                          // Show confirmation dialog
                          final shouldClear = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Clear All Data'),
                              content: const Text('This will delete all talks and photos. This cannot be undone.'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text('Clear'),
                                ),
                              ],
                            ),
                          );

                          if (shouldClear == true) {
                            await widget.storageService.clearAllData();
                            setState(() {
                              talks = [];
                            });
                          }
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem<String>(
                          value: 'clear_data',
                          child: Text('Clear All Data'),
                        ),
                      ],
                    ),
                ],
              )
            : ContextualAppBar(
                title: '${_selectedTalks.length} selected',
                backgroundColor: Colors.grey[800]!,
                leading: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: _clearSelection,
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: _deleteSelectedTalks,
                  ),
                ],
              ),
        body: talks.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // App logo container (replace with actual logo)
                    Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        color: AppTheme.accentColor,
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Center(
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // App logo placeholder
                            Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor,
                                borderRadius: BorderRadius.circular(60),
                              ),
                              child: const Icon(
                                Icons.camera_alt_outlined,
                                size: 60,
                                color: AppTheme.accentColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 48),
                    const Text(
                      'Create a talk to get started',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 48),
                    EmptyStateTile(onTap: _showCreateTalkSheet),
                  ],
                ),
              )
            : Column(
                children: [

                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.only(top: 8, bottom: 80),
                      itemCount: talks.length,
                      itemBuilder: (context, index) {
                        final talk = talks[index];
                        return Dismissible(
                          key: Key(talk.id),
                          direction: DismissDirection.startToEnd,
                          onDismissed: (direction) async {
                            final deletedTalkId = talk.id;
                            setState(() {
                              talks.removeAt(index);
                              _pendingDeletions[deletedTalkId] = talk;
                            });

                            showUndoSnackBar(
                              message: 'Talk deleted',
                              onUndo: () {
                                setState(() {
                                  if (_pendingDeletions.containsKey(deletedTalkId)) {
                                    talks.insert(index, _pendingDeletions[deletedTalkId]!);
                                    _pendingDeletions.remove(deletedTalkId);
                                  }
                                });
                              },
                              onDismissed: () async {
                                if (_pendingDeletions.containsKey(deletedTalkId)) {
                                  await widget.storageService.deleteTalk(_pendingDeletions[deletedTalkId]!.id);
                                  _pendingDeletions.remove(deletedTalkId);
                                }
                              },
                            );
                          },
                          background: Container(
                            color: Colors.red,
                            alignment: Alignment.centerLeft,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: const Icon(Icons.delete, color: Colors.white),
                          ),
                          child: TalkCard(
                            talk: talk,
                            onTap: () => _navigateToTalkView(talk),
                            onLongPress: () => _handleTalkLongPress(talk.id),
                            isSelected: _selectedTalks.contains(talk.id),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
                floatingActionButton: Hero(
          tag: 'camera-fab',
          child: FlowerShapedFab(
            onPressed: _showCreateTalkSheet,
            icon: Icons.add,
          ),
        ),
      ),
    );
  }
}