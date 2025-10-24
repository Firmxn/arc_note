import 'package:flutter/material.dart';
import '../../data/models/block_model.dart';
import 'note_editor.dart';

class BlockEditor extends StatefulWidget {
  final BlockModel block;
  final int index;
  final Function(Map<String, dynamic>) onChanged;
  final Function(BlockAction) onAction;

  const BlockEditor({
    super.key,
    required this.block,
    required this.index,
    required this.onChanged,
    required this.onAction,
  });

  @override
  State<BlockEditor> createState() => BlockEditorState();
}

class BlockEditorState extends State<BlockEditor> {
  final FocusNode _focusNode = FocusNode();
  late TextEditingController _textController;
  bool _isHovered = false;
  bool _showMenu = false;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
    _initializeContent();
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    super.dispose();
  }

  void _initializeContent() {
    switch (widget.block.type) {
      case BlockType.text:
      case BlockType.heading:
      case BlockType.quote:
        _textController.text = widget.block.textContent;
        break;
      case BlockType.code:
        _textController.text = widget.block.content['code'] ?? '';
        break;
      default:
        _textController.text = '';
    }
  }

  void _onFocusChanged() {
    setState(() {
      _showMenu = _focusNode.hasFocus;
    });
  }

  void _onTextChanged(String text) {
    Map<String, dynamic> newContent;
    switch (widget.block.type) {
      case BlockType.text:
      case BlockType.heading:
      case BlockType.quote:
        newContent = {'text': text};
        break;
      case BlockType.code:
        newContent = {
          'code': text,
          'language': widget.block.content['language'] ?? 'plain',
        };
        break;
      default:
        newContent = widget.block.content;
    }

    widget.onChanged(newContent);
  }

  void _requestFocus() {
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Container(
        key: ValueKey('block_${widget.block.id}'),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: _showMenu
                ? Theme.of(context).colorScheme.primary
                : _isHovered
                    ? Theme.of(context).colorScheme.outline.withOpacity(0.3)
                    : Colors.transparent,
            width: _showMenu ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            // Block menu
            if (_showMenu || _isHovered)
              _buildBlockMenu(),

            // Block content
            _buildBlockContent(),

            // Block handle for dragging
            if (_isHovered)
              _buildDragHandle(),
          ],
        ),
      ),
    );
  }

  Widget _buildBlockMenu() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(8),
          topRight: Radius.circular(8),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.drag_handle,
            size: 16,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
          const SizedBox(width: 8),
          Text(
            _getBlockTypeDisplayName(),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          PopupMenuButton<BlockAction>(
            icon: Icon(
              Icons.more_vert,
              size: 16,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
            onSelected: widget.onAction,
            itemBuilder: (context) => [
              PopupMenuItem(
                value: BlockAction(
                  type: BlockActionType.addBefore,
                  index: widget.index,
                ),
                child: _buildMenuItem('Add block before', Icons.add_circle_outline),
              ),
              PopupMenuItem(
                value: BlockAction(
                  type: BlockActionType.addAfter,
                  index: widget.index,
                ),
                child: _buildMenuItem('Add block after', Icons.add_circle_outline),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: BlockAction(
                  type: BlockActionType.changeType,
                  index: widget.index,
                ),
                child: _buildMenuItem('Change type', Icons.edit),
              ),
              if (widget.index > 0)
                PopupMenuItem(
                  value: BlockAction(
                    type: BlockActionType.moveUp,
                    index: widget.index,
                  ),
                  child: _buildMenuItem('Move up', Icons.keyboard_arrow_up),
                ),
              if (widget.index < 100) // Assuming max 100 blocks
                PopupMenuItem(
                  value: BlockAction(
                    type: BlockActionType.moveDown,
                    index: widget.index,
                  ),
                  child: _buildMenuItem('Move down', Icons.keyboard_arrow_down),
                ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: BlockAction(
                  type: BlockActionType.delete,
                  index: widget.index,
                ),
                child: _buildMenuItem('Delete', Icons.delete_outline, Colors.red),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(String text, IconData icon, [Color? color]) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 12),
        Text(text, style: color != null ? TextStyle(color: color) : null),
      ],
    );
  }

  Widget _buildBlockContent() {
    switch (widget.block.type) {
      case BlockType.text:
        return _buildTextBlock();
      case BlockType.heading:
        return _buildHeadingBlock();
      case BlockType.list:
        return _buildListBlock();
      case BlockType.checkbox:
        return _buildCheckboxBlock();
      case BlockType.quote:
        return _buildQuoteBlock();
      case BlockType.code:
        return _buildCodeBlock();
      case BlockType.divider:
        return _buildDividerBlock();
      case BlockType.image:
        return _buildImageBlock();
      default:
        return _buildTextBlock();
    }
  }

  Widget _buildTextBlock() {
    return TextField(
      controller: _textController,
      focusNode: _focusNode,
      decoration: const InputDecoration(
        border: InputBorder.none,
        hintText: 'Start typing...',
        contentPadding: EdgeInsets.all(16),
      ),
      style: Theme.of(context).textTheme.bodyLarge,
      maxLines: null,
      onChanged: _onTextChanged,
      onTap: _requestFocus,
    );
  }

  Widget _buildHeadingBlock() {
    final level = widget.block.content['level'] ?? 1;
    double fontSize;
    FontWeight fontWeight;

    switch (level) {
      case 1:
        fontSize = 32;
        fontWeight = FontWeight.bold;
        break;
      case 2:
        fontSize = 24;
        fontWeight = FontWeight.bold;
        break;
      case 3:
        fontSize = 20;
        fontWeight = FontWeight.w600;
        break;
      default:
        fontSize = 18;
        fontWeight = FontWeight.w500;
    }

    return TextField(
      controller: _textController,
      focusNode: _focusNode,
      decoration: const InputDecoration(
        border: InputBorder.none,
        hintText: 'Heading',
        contentPadding: EdgeInsets.all(16),
      ),
      style: Theme.of(context).textTheme.displaySmall?.copyWith(
        fontSize: fontSize,
        fontWeight: fontWeight,
      ),
      maxLines: 1,
      onChanged: _onTextChanged,
      onTap: _requestFocus,
    );
  }

  Widget _buildListBlock() {
    final items = List<String>.from(widget.block.content['items'] ?? ['']);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < items.length; i++)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 16, left: 16, right: 8),
                child: Icon(
                  Icons.circle,
                  size: 6,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: 'List item',
                    contentPadding: EdgeInsets.all(16),
                  ),
                  controller: TextEditingController(text: items[i]),
                  onChanged: (value) {
                    items[i] = value;
                    widget.onChanged({'items': items});
                  },
                ),
              ),
              if (items.length > 1)
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed: () {
                    items.removeAt(i);
                    widget.onChanged({'items': items});
                  },
                ),
            ],
          ),
        Padding(
          padding: const EdgeInsets.only(left: 16),
          child: TextButton.icon(
            onPressed: () {
              items.add('');
              widget.onChanged({'items': items});
            },
            icon: const Icon(Icons.add),
            label: const Text('Add item'),
          ),
        ),
      ],
    );
  }

  Widget _buildCheckboxBlock() {
    final items = List<Map<String, dynamic>>.from(
      widget.block.content['items'] ?? [{'text': '', 'checked': false}]
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < items.length; i++)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 16, left: 16, right: 8),
                child: Checkbox(
                  value: items[i]['checked'] ?? false,
                  onChanged: (value) {
                    items[i]['checked'] = value ?? false;
                    widget.onChanged({'items': items});
                  },
                ),
              ),
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Checkbox item',
                    contentPadding: EdgeInsets.all(16),
                  ),
                  controller: TextEditingController(text: items[i]['text'] ?? ''),
                  onChanged: (value) {
                    items[i]['text'] = value;
                    widget.onChanged({'items': items});
                  },
                ),
              ),
              if (items.length > 1)
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed: () {
                    items.removeAt(i);
                    widget.onChanged({'items': items});
                  },
                ),
            ],
          ),
        Padding(
          padding: const EdgeInsets.only(left: 16),
          child: TextButton.icon(
            onPressed: () {
              items.add({'text': '', 'checked': false});
              widget.onChanged({'items': items});
            },
            icon: const Icon(Icons.add),
            label: const Text('Add item'),
          ),
        ),
      ],
    );
  }

  Widget _buildQuoteBlock() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.format_quote,
            size: 24,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _textController,
            focusNode: _focusNode,
            decoration: const InputDecoration(
              border: InputBorder.none,
              hintText: 'Quote',
            ),
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontStyle: FontStyle.italic,
            ),
            maxLines: null,
            onChanged: _onTextChanged,
            onTap: _requestFocus,
          ),
        ],
      ),
    );
  }

  Widget _buildCodeBlock() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.code,
                size: 16,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Text(
                widget.block.content['language'] ?? 'plain',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              Icon(
                Icons.content_copy,
                size: 16,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _textController,
            focusNode: _focusNode,
            decoration: const InputDecoration(
              border: InputBorder.none,
              hintText: 'Code',
            ),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontFamily: 'monospace',
            ),
            maxLines: null,
            onChanged: _onTextChanged,
            onTap: _requestFocus,
          ),
        ],
      ),
    );
  }

  Widget _buildDividerBlock() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Divider(
        color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
        thickness: 1,
      ),
    );
  }

  Widget _buildImageBlock() {
    final imageUrl = widget.block.content['url'] ?? '';
    final alt = widget.block.content['alt'] ?? '';

    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (imageUrl.isNotEmpty)
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Theme.of(context).colorScheme.surfaceVariant,
              ),
              child: imageUrl.startsWith('http')
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.broken_image),
                                const SizedBox(height: 8),
                                Text(
                                  'Failed to load image',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    )
                  : Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.image),
                          const SizedBox(height: 8),
                          Text(
                            'Image URL',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
            ),
          const SizedBox(height: 8),
          TextField(
            decoration: const InputDecoration(
              labelText: 'Image URL',
              border: OutlineInputBorder(),
            ),
            controller: TextEditingController(text: imageUrl),
            onChanged: (value) {
              widget.onChanged({
                'url': value,
                'alt': alt,
              });
            },
          ),
          const SizedBox(height: 8),
          TextField(
            decoration: const InputDecoration(
              labelText: 'Alt text (optional)',
              border: OutlineInputBorder(),
            ),
            controller: TextEditingController(text: alt),
            onChanged: (value) {
              widget.onChanged({
                'url': imageUrl,
                'alt': value,
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDragHandle() {
    return Positioned(
      left: 0,
      top: 0,
      bottom: 0,
      child: Container(
        width: 8,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(8),
            bottomLeft: Radius.circular(8),
          ),
        ),
        child: Icon(
          Icons.drag_handle,
          color: Theme.of(context).colorScheme.onPrimary,
          size: 16,
        ),
      ),
    );
  }

  String _getBlockTypeDisplayName() {
    switch (widget.block.type) {
      case BlockType.text:
        return 'Text';
      case BlockType.heading:
        return 'Heading';
      case BlockType.list:
        return 'List';
      case BlockType.checkbox:
        return 'Checkbox';
      case BlockType.quote:
        return 'Quote';
      case BlockType.code:
        return 'Code';
      case BlockType.divider:
        return 'Divider';
      case BlockType.image:
        return 'Image';
    }
  }
}