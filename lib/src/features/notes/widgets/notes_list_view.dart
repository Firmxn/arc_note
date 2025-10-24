import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/page_model.dart';
import '../../data/repositories/page_repository.dart';
import '../../core/utils/app_extensions.dart';

class NotesListView extends ConsumerStatefulWidget {
  final String userId;
  final String searchQuery;

  const NotesListView({
    super.key,
    required this.userId,
    required this.searchQuery,
  });

  @override
  ConsumerState<NotesListView> createState() => _NotesListViewState();
}

class _NotesListViewState extends ConsumerState<NotesListView> {
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _refreshNotes() async {
    setState(() {
      _isLoading = true;
    });

    final repository = ref.read(pageRepositoryProvider);
    final result = await repository.getByUserId(widget.userId);

    setState(() {
      _isLoading = false;
    });

    if (!result.success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to refresh notes: ${result.error ?? "Unknown error"}'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  void _navigateToNote(PageModel page) {
    context.push('/note/${page.id}');
  }

  Future<void> _deleteNote(PageModel page) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Note'),
        content: Text('Are you sure you want to delete "${page.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final repository = ref.read(pageRepositoryProvider);
      final result = await repository.delete(page.id);

      if (!result.success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete note: ${result.error ?? "Unknown error"}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refreshNotes,
      child: FutureBuilder(
        future: _getNotes(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to load notes',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    snapshot.error.toString(),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _refreshNotes,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final notes = snapshot.data ?? [];
          final filteredNotes = _filterNotes(notes, widget.searchQuery);

          if (filteredNotes.isEmpty) {
            if (widget.searchQuery.isNotEmpty) {
              return _buildNoSearchResultsView();
            } else {
              return const EmptyNotesView();
            }
          }

          return ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            itemCount: filteredNotes.length,
            itemBuilder: (context, index) {
              final note = filteredNotes[index];
              return NoteCard(
                note: note,
                onTap: () => _navigateToNote(note),
                onDelete: () => _deleteNote(note),
              );
            },
          );
        },
      ),
    );
  }

  Future<List<PageModel>> _getNotes() async {
    final repository = ref.read(pageRepositoryProvider);
    final result = await repository.getByUserId(widget.userId);

    if (result.success) {
      return result.data ?? [];
    } else {
      throw Exception(result.error ?? 'Failed to load notes');
    }
  }

  List<PageModel> _filterNotes(List<PageModel> notes, String query) {
    if (query.isEmpty) return notes;

    return notes.where((note) {
      return note.title.toLowerCase().contains(query.toLowerCase()) ||
             (note.content?.toLowerCase().contains(query.toLowerCase()) ?? false);
    }).toList();
  }

  Widget _buildNoSearchResultsView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'No results found',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try searching with different keywords',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class NoteCard extends StatelessWidget {
  final PageModel note;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const NoteCard({
    super.key,
    required this.note,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      note.title.isEmpty ? 'Untitled Note' : note.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'delete') {
                        onDelete();
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete'),
                          ],
                        ),
                      ),
                    ],
                    child: Icon(
                      Icons.more_vert,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              if (note.content != null && note.content!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  note.content!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.schedule,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    note.updatedAt.timeAgo,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const Spacer(),
                  // Sync status indicator
                  Icon(
                    _getSyncStatusIcon(note.syncStatus),
                    size: 16,
                    color: _getSyncStatusColor(context, note.syncStatus),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _getSyncStatusText(note.syncStatus),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: _getSyncStatusColor(context, note.syncStatus),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getSyncStatusIcon(SyncStatus status) {
    switch (status) {
      case SyncStatus.synced:
        return Icons.cloud_done;
      case SyncStatus.pending:
        return Icons.cloud_upload;
      case SyncStatus.error:
        return Icons.cloud_off;
      case SyncStatus.conflict:
        return Icons.cloud_sync;
    }
  }

  Color _getSyncStatusColor(BuildContext context, SyncStatus status) {
    switch (status) {
      case SyncStatus.synced:
        return Theme.of(context).colorScheme.primary;
      case SyncStatus.pending:
        return Theme.of(context).colorScheme.secondary;
      case SyncStatus.error:
        return Theme.of(context).colorScheme.error;
      case SyncStatus.conflict:
        return Theme.of(context).colorScheme.tertiary;
    }
  }

  String _getSyncStatusText(SyncStatus status) {
    switch (status) {
      case SyncStatus.synced:
        return 'Synced';
      case SyncStatus.pending:
        return 'Syncing';
      case SyncStatus.error:
        return 'Error';
      case SyncStatus.conflict:
        return 'Conflict';
    }
  }
}