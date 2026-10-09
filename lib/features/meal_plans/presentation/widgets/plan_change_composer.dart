import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/extensions/context_extensions.dart';

/// "Bu planı değiştir": örnek istekler ve serbest metin alanı.
class PlanChangeComposer extends StatefulWidget {
  const PlanChangeComposer({
    super.key,
    required this.busy,
    required this.onSubmit,
  });

  final bool busy;
  final ValueChanged<String> onSubmit;

  @override
  State<PlanChangeComposer> createState() => _PlanChangeComposerState();
}

class _PlanChangeComposerState extends State<PlanChangeComposer> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _send([String? text]) {
    final value = (text ?? _controller.text).trim();
    if (value.isEmpty || widget.busy) return;
    widget.onSubmit(value);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final suggestions = [
      l10n.planSuggestionDislike,
      l10n.planSuggestionSwapDinner,
      l10n.planSuggestionNoEggBreakfast,
      l10n.planSuggestionFish,
      l10n.planSuggestionWholePlan,
    ];
    return Material(
      color: context.colors.surfaceContainer,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.sm,
            AppSpacing.sm,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 40,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: suggestions.length,
                  separatorBuilder: (_, _) => AppSpacing.gapSm,
                  itemBuilder: (context, index) => ActionChip(
                    label: Text(suggestions[index]),
                    onPressed: widget.busy
                        ? null
                        : () => _send(suggestions[index]),
                  ),
                ),
              ),
              AppSpacing.gapSm,
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      enabled: !widget.busy,
                      textInputAction: TextInputAction.send,
                      textCapitalization: TextCapitalization.sentences,
                      onSubmitted: (_) => _send(),
                      decoration: InputDecoration(
                        hintText: l10n.planChangeHint,
                        isDense: true,
                      ),
                    ),
                  ),
                  IconButton.filled(
                    tooltip: l10n.planChangeSend,
                    onPressed: widget.busy ? null : _send,
                    icon: widget.busy
                        ? const SizedBox.square(
                            dimension: AppSizes.iconSm,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send_rounded),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
