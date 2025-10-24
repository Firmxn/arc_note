import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/block_model.dart';
import '../widgets/block_editor.dart';

class NoteEditor extends ConsumerStatefulWidget {
  final String pageId;
  final List<BlockModel> blocks;
  final VoidCallback onChanged;
  final Function(List<BlockModel>) onBlocksChanged;

  const NoteEditor({
    super.key,
    required this.pageId,
    required this.blocks,
    required this.onChanged,
    required this.onBlocksChanged,
  });

  @override
  ConsumerState<NoteEditor> createState() => _NoteEditorState();
}

class _NoteEditorState extends ConsumerState<NoteEditor> {
  final ScrollController _scrollController = ScrollController();
  final List<GlobalKey<BlockEditorState>> _blockKeys = [];
  final FocusNode _contentFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _initializeBlocks();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _contentFocusNode.dispose();
    super.dispose();
  }

  void _initializeBlocks() {
    // Create keys for existing blocks
    _blockKeys.clear();
    for (int i = 0; i < widget.blocks.length; i++) {
      _blockKeys.add(GlobalKey<BlockEditorState>());
    }

    // If no blocks, create an initial text block
    if (widget.blocks.isEmpty) {
      _addNewBlock(BlockType.text, atIndex: 0);
    }
  }

  void _addNewBlock(BlockType type, {int? atIndex}) {
    final newBlock = BlockModel(
      pageId: widget.pageId,
      type: type,
      content: _getDefaultContentForType(type),
      order: atIndex != null ? atIndex.toDouble() : widget.blocks.length.toDouble(),
    );

    setState(() {
      if (atIndex != null && atIndex < widget.blocks.length) {
        widget.blocks.insert(atIndex, newBlock);
        _blockKeys.insert(atIndex, GlobalKey<BlockEditorState>());
      } else {
        widget.blocks.add(newBlock);
        _blockKeys.add(GlobalKey<BlockEditorState>());
      }

      // Update order for all blocks
      _updateBlockOrders();
    });

    widget.onBlocksChanged(widget.blocks);
    widget.onChanged();

    // Focus the new block
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (atIndex != null) {
        _focusBlock(atIndex);
      } else {
        _focusBlock(widget.blocks.length - 1);
      }
    });
  }

  Map<String, dynamic> _getDefaultContentForType(BlockType type) {
    switch (type) {
      case BlockType.text:
        return {'text': ''};
      case BlockType.heading:
        return {'text': 'Heading', 'level': 1};
      case BlockType.list:
        return {'items': ['']};
      case BlockType.checkbox:
        return {'items': [{'text': '', 'checked': false}]};
      case BlockType.quote:
        return {'text': ''};
      case BlockType.code:
        return {'code': '', 'language': 'plain'};
      case BlockType.divider:
        return {};
      case BlockType.image:
        return {'url': '', 'alt': ''};
    }
  }

  void _updateBlockOrders() {
    for (int i = 0; i < widget.blocks.length; i++) {
      widget.blocks[i] = widget.blocks[i].copyWith(order: i.toDouble());
    }
  }

  void _focusBlock(int index) {
    if (index >= 0 && index < _blockKeys.length) {
      _blockKeys[index].currentState?.requestFocus();
    }
  }

  void _updateBlockContent(int index, Map<String, dynamic> content) {
    if (index >= 0 && index < widget.blocks.length) {
      final updatedBlock = widget.blocks[index].copyWith(
        content: content,
        updatedAt: DateTime.now(),
      );
      updatedBlock.markForSync();

      setState(() {
        widget.blocks[index] = updatedBlock;
      });

      widget.onBlocksChanged(widget.blocks);
      widget.onChanged();
    }
  }

  void _deleteBlock(int index) {
    if (widget.blocks.length > 1) {
      setState(() {
        widget.blocks.removeAt(index);
        _blockKeys.removeAt(index);
        _updateBlockOrders();
      });

      widget.onBlocksChanged(widget.blocks);
      widget.onChanged();

      // Focus previous block or next block
      if (index > 0) {
        _focusBlock(index - 1);
      } else if (widget.blocks.isNotEmpty) {
        _focusBlock(0);
      }
    }
  }

  void _reorderBlocks(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final block = widget.blocks.removeAt(oldIndex);
    final key = _blockKeys.removeAt(oldIndex);
    widget.blocks.insert(newIndex, block);
    _blockKeys.insert(newIndex, key);

    _updateBlockOrders();
    widget.onBlocksChanged(widget.blocks);
    widget.onChanged();
  }

  void _handleBlockAction(BlockAction action) {
    switch (action.type) {
      case BlockActionType.addBefore:
        _addNewBlock(action.blockType ?? BlockType.text, atIndex: action.index);
        break;
      case BlockActionType.addAfter:
        _addNewBlock(action.blockType ?? BlockType.text, atIndex: action.index + 1);
        break;
      case BlockActionType.delete:
        _deleteBlock(action.index);
        break;
      case BlockActionType.changeType:
        _changeBlockType(action.index, action.blockType!);
        break;
      case BlockActionType.moveUp:
        if (action.index > 0) {
          _reorderBlocks(action.index, action.index - 1);
        }
        break;
      case BlockActionType.moveDown:
        if (action.index < widget.blocks.length - 1) {
          _reorderBlocks(action.index, action.index + 1);
        }
        break;
    }
  }

  void _changeBlockType(int index, BlockType newType) {
    if (index >= 0 && index < widget.blocks.length) {
      final currentBlock = widget.blocks[index];
      final newContent = _convertContent(currentBlock.content, currentBlock.type, newType);

      final updatedBlock = currentBlock.copyWith(
        type: newType,
        content: newContent,
        updatedAt: DateTime.now(),
      );
      updatedBlock.markForSync();

      setState(() {
        widget.blocks[index] = updatedBlock;
      });

      widget.onBlocksChanged(widget.blocks);
      widget.onChanged();
    }
  }

  Map<String, dynamic> _convertContent(
    Map<String, dynamic> currentContent,
    BlockType fromType,
    BlockType toType,
  ) {
    // Simple content conversion - can be enhanced
    switch (toType) {
      case BlockType.text:
      case BlockType.heading:
      case BlockType.quote:
        return {'text': currentContent['text'] ?? ''};
      case BlockType.list:
        return {'items': [currentContent['text'] ?? '']};
      case BlockType.checkbox:
        return {'items': [{'text': currentContent['text'] ?? '', 'checked': false}]};
      default:
        return _getDefaultContentForType(toType);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Block type selector (hidden by default, shown when needed)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
            border: Border(
              bottom: BorderSide(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
              ),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.edit_note_outlined,
                size: 20,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Text(
                'Note Content',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                onPressed: () => _showBlockTypeSelector(-1),
                tooltip: 'Add Block',
              ),
            ],
          ),
        ),

        // Blocks list
        Expanded(
          child: ReorderableListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(vertical: 8),
            onReorder: _reorderBlocks,
            itemCount: widget.blocks.length,
            itemBuilder: (context, index) {
              final block = widget.blocks[index];
              final key = ValueKey('${block.id}_${block.order}');

              return BlockEditor(
                key: _blockKeys[index] ?? GlobalKey<BlockEditorState>(),
                block: block,
                index: index,
                onChanged: (content) => _updateBlockContent(index, content),
                onAction: _handleBlockAction,
              );
            },
          ),
        ),

        // Quick add bar at bottom
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(
              top: BorderSide(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
              ),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.add_circle_outline,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Add block',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const Spacer(),
              PopupMenuButton<BlockType>(
                icon: Icon(
                  Icons.add,
                  color: Theme.of(context).colorScheme.primary,
                ),
                onSelected: (type) => _addNewBlock(type),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: BlockType.text,
                    child: _buildBlockTypeMenuItem('Text', Icons.text_fields),
                  ),
                  PopupMenuItem(
                    value: BlockType.heading,
                    child: _buildBlockTypeMenuItem('Heading', Icons.title),
                  ),
                  PopupMenuItem(
                    value: BlockType.list,
                    child: _buildBlockTypeMenuItem('List', Icons.list),
                  ),
                  PopupMenuItem(
                    value: BlockType.checkbox,
                    child: _buildBlockTypeMenuItem('Checkbox', Icons.check_box),
                  ),
                  PopupMenuItem(
                    value: BlockType.quote,
                    child: _buildBlockTypeMenuItem('Quote', Icons.format_quote),
                  ),
                  PopupMenuItem(
                    value: BlockType.code,
                    child: _buildBlockTypeMenuItem('Code', Icons.code),
                  ),
                  PopupMenuItem(
                    value: BlockType.divider,
                    child: _buildBlockTypeMenuItem('Divider', Icons.horizontal_rule),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBlockTypeMenuItem(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18),
        const SizedBox(width: 12),
        Text(title),
      ],
    );
  }

  void _showBlockTypeSelector(int insertIndex) {
    showModalBottomSheet(
      context: context,
      builder: (context) => BlockTypeSelector(
        onSelected: (type) {
          Navigator.pop(context);
          _addNewBlock(type, atIndex: insertIndex + 1);
        },
      ),
    );
  }
}

// Block action types
enum BlockActionType {
  addBefore,
  addAfter,
  delete,
  changeType,
  moveUp,
  moveDown,
}

class BlockAction {
  final BlockActionType type;
  final int index;
  final BlockType? blockType;

  BlockAction({
    required this.type,
    required this.index,
    this.blockType,
  });
}

// Block type selector modal
class BlockTypeSelector extends StatelessWidget {
  final Function(BlockType) onSelected;

  const BlockTypeSelector({
    super.key,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Add Block',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            crossAxisCount: 4,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            children: [
              _buildBlockTypeButton(context, 'Text', Icons.text_fields, BlockType.text),
              _buildBlockTypeButton(context, 'Heading', Icons.title, BlockType.heading),
              _buildBlockTypeButton(context, 'List', Icons.list, BlockType.list),
              _buildBlockTypeButton(context, 'Checkbox', Icons.check_box, BlockType.checkbox),
              _buildBlockTypeButton(context, 'Quote', Icons.format_quote, BlockType.quote),
              _buildBlockTypeButton(context, 'Code', Icons.code, BlockType.code),
              _buildBlockTypeButton(context, 'Divider', Icons.horizontal_rule, BlockType.divider),
              _buildBlockTypeButton(context, 'Image', Icons.image, BlockType.image),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBlockTypeButton(
    BuildContext context,
    String title,
    IconData icon,
    BlockType type,
  ) {
    return InkWell(
      onTap: () => onSelected(type),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 24),
            const SizedBox(height: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}