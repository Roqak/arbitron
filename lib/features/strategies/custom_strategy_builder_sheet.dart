import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/app_cubit.dart';
import '../../core/domain/custom_strategy.dart';
import '../../core/domain/enums.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/widgets.dart';

/// No-code custom strategy builder. Composes rules visually without editing
/// config fields. See PRD §12 (v2.5 — Custom strategy builder).
class CustomStrategyBuilderSheet extends StatefulWidget {
  final CustomStrategy? existing;
  const CustomStrategyBuilderSheet({super.key, this.existing});

  @override
  State<CustomStrategyBuilderSheet> createState() => _CustomStrategyBuilderSheetState();
}

class _CustomStrategyBuilderSheetState extends State<CustomStrategyBuilderSheet> {
  late CustomStrategy _draft;
  late final TextEditingController _nameCtrl;
  late final TextEditingController _maxTradeCtrl;
  late final TextEditingController _stopLossCtrl;

  @override
  void initState() {
    super.initState();
    _draft = widget.existing ??
        const CustomStrategy(id: 'custom_new', name: 'My Custom Strategy');
    _nameCtrl = TextEditingController(text: _draft.name);
    _maxTradeCtrl = TextEditingController(text: _draft.maxTradeUsd.toStringAsFixed(0));
    _stopLossCtrl = TextEditingController(text: _draft.stopLossDailyUsd.toStringAsFixed(0));
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _maxTradeCtrl.dispose();
    _stopLossCtrl.dispose();
    super.dispose();
  }

  void _addRule() {
    setState(() {
      _draft = _draft.copyWith(rules: [..._draft.rules, const StrategyRule(field: RuleField.netProfitUsd, op: RuleOperator.gte, value: 10)]);
    });
  }

  void _removeRule(int index) {
    setState(() {
      final rules = List<StrategyRule>.from(_draft.rules)..removeAt(index);
      _draft = _draft.copyWith(rules: rules);
    });
  }

  void _updateRule(int index, StrategyRule rule) {
    setState(() {
      final rules = List<StrategyRule>.from(_draft.rules);
      rules[index] = rule;
      _draft = _draft.copyWith(rules: rules);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          color: theme.surfaceOverlay,
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.xl, AppSpacing.xl, AppSpacing.xxxl),
            children: [
              Center(child: Container(width: 32, height: 4, decoration: BoxDecoration(color: theme.borderStrong, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: AppSpacing.xl),
              Row(
                children: [
                  Icon(Icons.widgets_outlined, color: theme.accent, size: 24),
                  const SizedBox(width: AppSpacing.sm),
                  Text('Custom Strategy Builder', style: theme.textTheme.headlineSmall!.copyWith(fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text('Compose rules visually \u2014 no config fields. Opportunities matching your rules will be surfaced.', style: theme.textTheme.bodySmall!.copyWith(color: theme.textMuted)),
              const SizedBox(height: AppSpacing.xl),
              _Label('Name'),
              const SizedBox(height: 6),
              TextField(controller: _nameCtrl, decoration: const InputDecoration(hintText: 'My Custom Strategy')),
              const SizedBox(height: AppSpacing.lg),
              _Label('Match'),
              const SizedBox(height: 6),
              SegmentedControl<RuleComposition>(
                segments: const [Segment(RuleComposition.and, 'ALL rules (AND)'), Segment(RuleComposition.or, 'ANY rule (OR)')],
                selected: _draft.composition,
                onChanged: (c) => setState(() => _draft = _draft.copyWith(composition: c)),
              ),
              const SizedBox(height: AppSpacing.xl),
              _Label('Rules (${_draft.rules.length})'),
              const SizedBox(height: AppSpacing.sm),
              if (_draft.rules.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  child: Text('No rules yet. Add a rule to start filtering opportunities.', style: theme.textTheme.bodyMedium!.copyWith(color: theme.textMuted)),
                )
              else
                ..._draft.rules.asMap().entries.map((e) => _RuleEditor(
                  rule: e.value,
                  onChanged: (r) => _updateRule(e.key, r),
                  onRemove: () => _removeRule(e.key),
                  index: e.key,
                )),
              const SizedBox(height: AppSpacing.sm),
              OutlinedButton.icon(
                onPressed: _addRule,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add rule'),
              ),
              const SizedBox(height: AppSpacing.xl),
              _Label('Execution mode'),
              const SizedBox(height: 6),
              SegmentedControl<ExecutionMode>(
                segments: const [
                  Segment(ExecutionMode.manual, 'Manual', icon: Icons.pan_tool_outlined),
                  Segment(ExecutionMode.semiAuto, 'Semi', icon: Icons.timer_outlined),
                  Segment(ExecutionMode.autonomous, 'Auto', icon: Icons.auto_mode),
                ],
                selected: _draft.mode,
                onChanged: (m) => setState(() => _draft = _draft.copyWith(mode: m)),
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(child: _LabeledField(label: 'Max trade (USD)', controller: _maxTradeCtrl, prefix: '\$')),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(child: _LabeledField(label: 'Stop-loss (USD)', controller: _stopLossCtrl, prefix: '\$')),
                ],
              ),
              const SizedBox(height: AppSpacing.xxl),
              Row(
                children: [
                  const Spacer(),
                  OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                  const SizedBox(width: AppSpacing.md),
                  FilledButton(
                    onPressed: () {
                      final saved = _draft.copyWith(
                        name: _nameCtrl.text.trim().isEmpty ? 'Custom Strategy' : _nameCtrl.text.trim(),
                        maxTradeUsd: double.tryParse(_maxTradeCtrl.text) ?? _draft.maxTradeUsd,
                        stopLossDailyUsd: double.tryParse(_stopLossCtrl.text) ?? _draft.stopLossDailyUsd,
                        id: widget.existing?.id ?? 'custom_${DateTime.now().millisecondsSinceEpoch}',
                      );
                      context.read<AppCubit>().addCustomStrategy(saved);
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Custom strategy saved'), duration: Duration(seconds: 2)));
                    },
                    child: const Text('Save strategy'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _RuleEditor extends StatelessWidget {
  final StrategyRule rule;
  final int index;
  final void Function(StrategyRule) onChanged;
  final VoidCallback onRemove;

  const _RuleEditor({required this.rule, required this.index, required this.onChanged, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ArbitronCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 24, height: 24,
                  decoration: BoxDecoration(color: theme.accentDim, borderRadius: BorderRadius.circular(6)),
                  child: Center(child: Text('${index + 1}', style: theme.textTheme.labelSmall!.copyWith(color: theme.accent, fontWeight: FontWeight.w700))),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: Text(rule.describe(), style: theme.textTheme.labelMedium!.copyWith(color: theme.textSecondary))),
                IconButton(icon: const Icon(Icons.close, size: 16), onPressed: onRemove, padding: EdgeInsets.zero, constraints: const BoxConstraints(minWidth: 32, minHeight: 32)),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            // Field picker
            Row(
              children: [
                Expanded(
                  child: _Dropdown<RuleField>(
                    value: rule.field,
                    items: RuleField.values,
                    labelBuilder: (f) => f.label,
                    onChanged: (f) => onChanged(StrategyRule(field: f, op: f.isText ? RuleOperator.eq : rule.op, value: rule.value, textValue: f.isText ? rule.textValue : null)),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _Dropdown<RuleOperator>(
                    value: rule.op,
                    items: rule.field.isText ? RuleOperator.values.where((o) => o.forText).toList() : RuleOperator.values.where((o) => !o.forText).toList(),
                    labelBuilder: (o) => o.label,
                    onChanged: (o) => onChanged(StrategyRule(field: rule.field, op: o, value: rule.value, textValue: rule.textValue)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            if (rule.field.isText)
              _TextInput(
                value: rule.textValue ?? '',
                hint: _hintForField(rule.field),
                onChanged: (v) => onChanged(StrategyRule(field: rule.field, op: rule.op, value: rule.value, textValue: v)),
              )
            else
              TextField(
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(hintText: '0', isDense: true),
                controller: TextEditingController(text: rule.value.toStringAsFixed(rule.value == rule.value.roundToDouble() ? 0 : 2)),
                onChanged: (v) => onChanged(StrategyRule(field: rule.field, op: rule.op, value: double.tryParse(v) ?? 0, textValue: rule.textValue)),
              ),
          ],
        ),
      ),
    );
  }

  String _hintForField(RuleField f) {
    return switch (f) {
      RuleField.pair => 'BTC/USDT',
      RuleField.buyExchange || RuleField.sellExchange => 'binance',
      _ => '',
    };
  }
}

class _Dropdown<T> extends StatelessWidget {
  final T value;
  final List<T> items;
  final String Function(T) labelBuilder;
  final void Function(T) onChanged;
  const _Dropdown({required this.value, required this.items, required this.labelBuilder, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(color: theme.surfaceRaised, borderRadius: BorderRadius.circular(AppRadius.sm)),
      child: DropdownButton<T>(
        value: value,
        isExpanded: true,
        underline: const SizedBox(),
        items: items.map((e) => DropdownMenuItem(value: e, child: Text(labelBuilder(e), style: theme.textTheme.labelMedium))).toList(),
        onChanged: (v) { if (v != null) onChanged(v); },
      ),
    );
  }
}

class _TextInput extends StatelessWidget {
  final String value;
  final String hint;
  final void Function(String) onChanged;
  const _TextInput({required this.value, required this.hint, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return TextField(
      decoration: InputDecoration(hintText: hint, isDense: true),
      controller: TextEditingController(text: value),
      onChanged: onChanged,
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(text, style: theme.textTheme.labelMedium!.copyWith(color: theme.textSecondary, fontWeight: FontWeight.w600));
  }
}

class _LabeledField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String? prefix;
  const _LabeledField({required this.label, required this.controller, this.prefix});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Label(label),
        const SizedBox(height: 6),
        TextField(controller: controller, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: prefix != null ? InputDecoration(prefixText: prefix) : null),
      ],
    );
  }
}