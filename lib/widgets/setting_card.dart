import 'package:flutter/material.dart';

/// One labeled value row, optionally maskable (for passwords, spec
/// section 18 requires masking by default + explicit reveal action) and
/// optionally editable.
class SettingRow extends StatefulWidget {
  final String label;
  final String value;
  final bool isSensitive;
  final VoidCallback? onEdit;
  final VoidCallback? onCopy;

  const SettingRow({
    super.key,
    required this.label,
    required this.value,
    this.isSensitive = false,
    this.onEdit,
    this.onCopy,
  });

  @override
  State<SettingRow> createState() => _SettingRowState();
}

class _SettingRowState extends State<SettingRow> {
  bool _revealed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayValue = widget.isSensitive && !_revealed ? '•' * 12 : widget.value;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.label, style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                )),
                const SizedBox(height: 2),
                Text(displayValue, style: theme.textTheme.titleMedium),
              ],
            ),
          ),
          if (widget.isSensitive)
            IconButton(
              icon: Icon(_revealed ? Icons.visibility_off_rounded : Icons.visibility_rounded),
              onPressed: () => setState(() => _revealed = !_revealed),
              tooltip: _revealed ? 'Hide' : 'Reveal',
            ),
          if (widget.onCopy != null)
            IconButton(
              icon: const Icon(Icons.copy_rounded),
              onPressed: widget.onCopy,
              tooltip: 'Copy',
            ),
          if (widget.onEdit != null)
            TextButton(onPressed: widget.onEdit, child: const Text('Edit')),
        ],
      ),
    );
  }
}

/// A card wrapping a section title + a list of [SettingRow]s.
class SettingSectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const SettingSectionCard({super.key, required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            const Divider(height: 20),
            ...children,
          ],
        ),
      ),
    );
  }
}
