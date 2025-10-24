import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/page_model.dart';
import '../../data/models/block_model.dart';
import '../../data/repositories/page_repository.dart';
import '../../data/repositories/block_repository.dart';
import '../widgets/note_editor.dart';
import '../widgets/loading_widget.dart';

class NoteDetailScreen extends ConsumerStatefulWidget {
  final String noteId;

  const NoteDetailScreen({
    super.key,
    required this.noteId,
  });

  @override
  ConsumerState<NoteDetailScreen> createState() => _NoteDetailScreenState();
}

class _NoteDetailScreenState extends ConsumerState<NoteDetailScreen> {
  final TextEditingController _titleController = TextEditingController();
  bool _isLoading = false;
  bool _hasUnsavedChanges = false;

  PageModel? _page;
  List<BlockModel> _blocks = [];

  @override
  void initState() {
    super.initState();
    _loadNote();
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _loadNote() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final noteId = int.parse(widget.noteId);
      final pageRepository = ref.read(pageRepositoryProvider);
      final blockRepository = ref.read(blockRepositoryProvider);

      // Load page
      final pageResult = await pageRepository.getById(noteId);
      if (pageResult.success && pageResult.data != null) {
        _page = pageResult.data!;
        _titleController.text = _page!.title;

        // Load blocks for this page
        final blocksResult = await blockRepository.getBlocksByPageId(_page!.remoteId ?? '');
        if (blocksResult.success) {
          _blocks = blocksResult.data ?? [];
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to load note: ${pageResult.error ?? "Unknown error"}'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
          context.pop();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading note: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
        context.pop();
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveNote() async {
    if (_page == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final pageRepository = ref.read(pageRepositoryProvider);
      final blockRepository = ref.read(blockRepositoryProvider);

      // Update page
      final updatedPage = _page!.copyWith(
        title: _titleController.text.trim(),
        updatedAt: DateTime.now(),
      );
      updatedPage.markForSync();

      final pageResult = await pageRepository.save(updatedPage);
      if (pageResult.success && pageResult.data != null) {
        _page = pageResult.data!;
      }

      // Save blocks
      if (_blocks.isNotEmpty) {
        final blocksResult = await blockRepository.saveMultiple(_blocks);
        if (blocksResult.success && blocksResult.data != null) {
          _blocks = blocksResult.data!;
        }
      }

      setState(() {
        _hasUnsavedChanges = false;
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Note saved successfully'),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving note: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _deleteNote() async {
    if (_page == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Note'),
        content: Text('Are you sure you want to delete "${_page!.title}"?'),
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
      setState(() {
        _isLoading = true;
      });

      try {
        final pageRepository = ref.read(pageRepositoryProvider);
        final blockRepository = ref.read(blockRepositoryProvider);

        // Delete blocks first
        if (_page!.remoteId != null) {
          await blockRepository.deleteBlocksByPageId(_page!.remoteId!);
        }

        // Delete page
        final result = await pageRepository.delete(_page!.id);

        if (result.success && mounted) {
          context.pop();
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete note: ${result.error ?? "Unknown error"}'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting note: ${e.toString()}'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _onContentChanged() {
    setState(() {
      _hasUnsavedChanges = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const LoadingWidget();
    }

    if (_page == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Note Not Found'),
        ),
        body: const Center(
          child: Text('Note not found'),
        ),
      );
    }

    return WillPopScope(
      onWillPop: () async {
        if (_hasUnsavedChanges) {
          final shouldLeave = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Unsaved Changes'),
              content: const Text('You have unsaved changes. Are you sure you want to leave?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Stay'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Leave'),
                ),
              ],
            ),
          );
          return shouldLeave ?? false;
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              border: InputBorder.none,
              hintText: 'Note Title',
            ),
            style: Theme.of(context).textTheme.titleLarge,
            onChanged: (_) => _onContentChanged(),
          ),
          actions: [
            if (_hasUnsavedChanges)
              IconButton(
                icon: const Icon(Icons.save),
                onPressed: _saveNote,
                tooltip: 'Save',
              ),
            PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'save':
                    _saveNote();
                    break;
                  case 'delete':
                    _deleteNote();
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'save',
                  child: Row(
                    children: [
                      Icon(Icons.save_outlined),
                      SizedBox(width: 8),
                      Text('Save'),
                    ],
                  ),
                ),
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
            ),
          ],
        ),
        body: NoteEditor(
          pageId: _page!.remoteId ?? '',
          blocks: _blocks,
          onChanged: _onContentChanged,
          onBlocksChanged: (blocks) {
            _blocks = blocks;
            _onContentChanged();
          },
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _hasUnsavedChanges ? _saveNote : null,
          icon: _hasUnsavedChanges
              ? const Icon(Icons.save)
              : const Icon(Icons.check),
          label: Text(_hasUnsavedChanges ? 'Save' : 'Saved'),
        ),
      ),
    );
  }
}