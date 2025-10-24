import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../auth/auth_notifier.dart';
import '../../data/models/page_model.dart';
import '../../data/repositories/page_repository.dart';
import '../widgets/notes_list_view.dart';
import '../widgets/empty_notes_view.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchQuery = '';
        _searchController.clear();
      }
    });
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
  }

  Future<void> _createNewNote() async {
    try {
      final currentUser = ref.read(currentUserProvider);
      if (currentUser == null) return;

      // Create a new page
      final newPage = PageModel(
        title: 'New Note',
        content: '',
        userId: currentUser.id,
      );

      final repository = ref.read(pageRepositoryProvider);
      final result = await repository.save(newPage);

      if (result.success && result.data != null) {
        // Navigate to the new note
        if (mounted) {
          context.push('/note/${result.data!.id}');
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to create note: ${result.error ?? "Unknown error"}'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating note: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Search notes...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                onChanged: _onSearchChanged,
              )
            : const Text('ArcNote'),
        actions: [
          if (_isSearching)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: _toggleSearch,
            )
          else
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: _toggleSearch,
            ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'sync':
                  _triggerSync();
                  break;
                case 'settings':
                  // TODO: Navigate to settings
                  break;
                case 'logout':
                  ref.read(authNotifierProvider.notifier).signOut();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'sync',
                child: Row(
                  children: [
                    Icon(Icons.sync_outlined),
                    SizedBox(width: 8),
                    Text('Sync Now'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings_outlined),
                    SizedBox(width: 8),
                    Text('Settings'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout_outlined),
                    SizedBox(width: 8),
                    Text('Logout'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: currentUser != null
          ? NotesListView(
              userId: currentUser.id,
              searchQuery: _searchQuery,
            )
          : const Center(
              child: Text('Please log in to view your notes'),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createNewNote,
        icon: const Icon(Icons.add),
        label: const Text('New Note'),
      ),
    );
  }

  void _triggerSync() {
    // TODO: Implement sync functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sync functionality coming soon')),
    );
  }
}

// Import the auth notifier
import '../../auth/auth_notifier.dart';