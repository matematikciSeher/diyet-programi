import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/extensions/context_extensions.dart';

typedef TagOption = ({String value, String label});

/// Çoklu seçim çipleri + kullanıcının kendi değerini ekleyebildiği alan.
class TagSelector extends StatefulWidget {
  const TagSelector({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
    required this.customHint,
    this.noneLabel,
    this.maxCustomLength = 40,
    this.maxItems = 20,
  });

  final List<TagOption> options;
  final List<String> selected;
  final ValueChanged<List<String>> onChanged;
  final String customHint;

  /// Verilirse, seçimi temizleyen "Yok" çipi gösterilir.
  final String? noneLabel;
  final int maxCustomLength;
  final int maxItems;

  @override
  State<TagSelector> createState() => _TagSelectorState();
}

class _TagSelectorState extends State<TagSelector> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  bool _isSelected(String value) => widget.selected.contains(value);

  void _toggle(String value) {
    final next = [...widget.selected];
    if (!next.remove(value)) {
      if (next.length >= widget.maxItems) return;
      next.add(value);
    }
    widget.onChanged(next);
  }

  void _addCustom() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    final lower = text.toLowerCase();
    final option = widget.options
        .where(
          (o) =>
              o.label.toLowerCase() == lower || o.value.toLowerCase() == lower,
        )
        .firstOrNull;
    final value = option?.value ?? text;
    final exists = widget.selected.any(
      (s) => s.toLowerCase() == value.toLowerCase(),
    );
    if (!exists && widget.selected.length < widget.maxItems) {
      widget.onChanged([...widget.selected, value]);
    }
    _controller.clear();
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final optionValues = widget.options.map((o) => o.value).toSet();
    final custom = widget.selected
        .where((s) => !optionValues.contains(s))
        .toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            if (widget.noneLabel != null)
              FilterChip(
                label: Text(widget.noneLabel!),
                selected: widget.selected.isEmpty,
                onSelected: (_) => widget.onChanged(const []),
              ),
            for (final option in widget.options)
              FilterChip(
                label: Text(option.label),
                selected: _isSelected(option.value),
                onSelected: (_) => _toggle(option.value),
              ),
            for (final value in custom)
              InputChip(
                label: Text(value),
                selected: true,
                showCheckmark: false,
                deleteButtonTooltipMessage: context.l10n.actionRemove,
                onDeleted: () => _toggle(value),
              ),
          ],
        ),
        AppSpacing.gapXl,
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                maxLength: widget.maxCustomLength,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _addCustom(),
                decoration: InputDecoration(
                  hintText: widget.customHint,
                  counterText: '',
                  prefixIcon: const Icon(Icons.add_rounded),
                ),
              ),
            ),
            AppSpacing.gapSm,
            IconButton.filledTonal(
              tooltip: context.l10n.actionAdd,
              onPressed: _addCustom,
              icon: const Icon(Icons.check_rounded),
            ),
          ],
        ),
      ],
    );
  }
}
