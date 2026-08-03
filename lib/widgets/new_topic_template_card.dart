import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

class NewTopicTemplateCard extends StatefulWidget {
  const NewTopicTemplateCard({
    super.key,
    required this.onConfirm,
  });

  final Future<void> Function(String name) onConfirm;

  @override
  State<NewTopicTemplateCard> createState() => _NewTopicTemplateCardState();
}

class _NewTopicTemplateCardState extends State<NewTopicTemplateCard> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  bool get _canConfirm =>
      !_submitting && _controller.text.trim().isNotEmpty;

  Future<void> _submit() async {
    final name = _controller.text.trim();
    if (name.isEmpty || _submitting) return;

    setState(() => _submitting = true);
    try {
      await widget.onConfirm(name);
      if (!mounted) return;
      _controller.clear();
      _focusNode.unfocus();
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.border.withValues(alpha: 0.9),
          style: BorderStyle.solid,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: AppColors.border.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.borderStrong.withValues(alpha: 0.35),
                ),
              ),
              child: Icon(
                Icons.sell_outlined,
                size: 22,
                color: AppColors.textMuted.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
                decoration: const InputDecoration(
                  isDense: true,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  hintText: 'Nombre del tópico',
                  hintStyle: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textMuted,
                  ),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Material(
              color: _canConfirm ? AppColors.ink : AppColors.border,
              borderRadius: BorderRadius.circular(10),
              child: InkWell(
                onTap: _canConfirm ? _submit : null,
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 40,
                  height: 40,
                  child: Icon(
                    Icons.check_rounded,
                    size: 20,
                    color: _canConfirm
                        ? Colors.white
                        : AppColors.textMuted.withValues(alpha: 0.45),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
