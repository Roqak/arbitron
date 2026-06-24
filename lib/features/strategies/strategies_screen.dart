import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/app_cubit.dart';
import '../../core/domain/enums.dart';
import '../../core/domain/strategy.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/fmt.dart';
import '../../core/widgets/widgets.dart';

/// Strategies screen — list + editor. See PRD §8.3.
class StrategiesScreen extends StatelessWidget {
  const StrategiesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: BlocBuilder<AppCubit, AppState>(
          buildWhen: (a, b) => a.strategies != b.strategies,
          builder: (context, state) {
            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: Padding(padding: EdgeInsets.fromLTRB(AppSpacing.screenH, AppSpacing.md, AppSpacing.screenH, AppSpacing.md), child: _Header())),
                if (state.strategies.isEmpty)
                  const SliverFillRemaining(hasScrollBody: false, child: EmptyState(icon: Icons.tune_outlined, title: 'No strategies configured', body: 'Add your first arbitrage strategy to begin.', actionLabel: 'Add strategy'))
                else
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(AppSpacing.screenH, 0, AppSpacing.screenH, AppSpacing.xxxl + 72),
                    sliver: SliverList.builder(
                      itemCount: state.strategies.length,
                      itemBuilder: (context, i) {
                        final s = state.strategies[i];
                        return Padding(padding: const EdgeInsets.only(bottom: AppSpacing.md), child: _StrategyCard(strategy: s, onTap: () => _showEditor(context, s)));
                      },
                    ),
                  ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showEditor(context, null),
        icon: const Icon(Icons.add),
        label: const Text('New strategy'),
        backgroundColor: Theme.of(context).accent,
        foregroundColor: Theme.of(context).background,
      ),
    );
  }

  void _showEditor(BuildContext context, Strategy? existing) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _StrategyEditorSheet(existing: existing),
    );
  }
}

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('Strategies', style: theme.textTheme.displayMedium!.copyWith(fontWeight: FontWeight.w700)),
        Text('Drag to reorder', style: theme.textTheme.labelMedium!.copyWith(color: theme.textMuted)),
      ],
    );
  }
}

class _StrategyCard extends StatelessWidget {
  final Strategy strategy;
  final VoidCallback onTap;
  const _StrategyCard({required this.strategy, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cubit = context.read<AppCubit>();
    final positive = strategy.totalPnl >= 0;
    return ArbitronCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(strategy.name, style: theme.textTheme.titleLarge!.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(strategy.type.label, style: theme.textTheme.labelMedium!.copyWith(color: theme.textSecondary)),
                  ],
                ),
              ),
              Switch(
                value: strategy.enabled,
                onChanged: (v) => cubit.toggleStrategyEnabled(strategy.id),
                activeColor: theme.accent,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              StatusChip(label: strategy.status.label, tone: strategy.status == StrategyStatus.active ? ChipTone.accent : ChipTone.neutral),
              const SizedBox(width: 8),
              ModeChip(mode: strategy.mode, compact: true),
              const Spacer(),
              Text('${strategy.totalTrades} trades', style: theme.textTheme.labelMedium!.copyWith(color: theme.textMuted)),
              const SizedBox(width: 8),
              Text(Fmt.signedUsd(strategy.totalPnl),
                  style: theme.textTheme.labelMedium!.copyWith(
                      color: positive ? theme.success : theme.danger, fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }
}

class _StrategyEditorSheet extends StatefulWidget {
  final Strategy? existing;
  const _StrategyEditorSheet({this.existing});

  @override
  State<_StrategyEditorSheet> createState() => _StrategyEditorSheetState();
}

class _StrategyEditorSheetState extends State<_StrategyEditorSheet> {
  late Strategy _draft;
  late final TextEditingController _nameCtrl;
  late final TextEditingController _instructionsCtrl;
  late final TextEditingController _minProfitCtrl;
  late final TextEditingController _maxTradeCtrl;
  late final TextEditingController _stopLossCtrl;

  @override
  void initState() {
    super.initState();
    _draft = widget.existing ??
        const Strategy(id: 'strat_new', name: 'New Strategy', type: StrategyType.simpleCrossExchange, enabled: true);
    _nameCtrl = TextEditingController(text: _draft.name);
    _instructionsCtrl = TextEditingController(text: _draft.customInstructions);
    _minProfitCtrl = TextEditingController(text: _draft.minProfitUsd.toStringAsFixed(0));
    _maxTradeCtrl = TextEditingController(text: _draft.maxTradeUsd.toStringAsFixed(0));
    _stopLossCtrl = TextEditingController(text: _draft.stopLossDailyUsd.toStringAsFixed(0));
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _instructionsCtrl.dispose();
    _minProfitCtrl.dispose();
    _maxTradeCtrl.dispose();
    _stopLossCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final cubit = context.read<AppCubit>();
    final updated = _draft.copyWith(
      name: _nameCtrl.text.trim().isEmpty ? 'New Strategy' : _nameCtrl.text.trim(),
      customInstructions: _instructionsCtrl.text.trim(),
      minProfitUsd: double.tryParse(_minProfitCtrl.text) ?? _draft.minProfitUsd,
      maxTradeUsd: double.tryParse(_maxTradeCtrl.text) ?? _draft.maxTradeUsd,
      stopLossDailyUsd: double.tryParse(_stopLossCtrl.text) ?? _draft.stopLossDailyUsd,
    );
    if (widget.existing == null) {
      cubit.addStrategy(updated.copyWith(id: 'strat_${DateTime.now().millisecondsSinceEpoch}'));
    } else {
      cubit.updateStrategy(updated);
    }
    Navigator.pop(context);
  }

  void _delete() {
    if (widget.existing != null) {
      context.read<AppCubit>().removeStrategy(widget.existing!.id);
      Navigator.pop(context);
    }
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
              Text(widget.existing == null ? 'New Strategy' : 'Edit Strategy', style: theme.textTheme.headlineSmall!.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: AppSpacing.xl),
              _Label('Name'),
              const SizedBox(height: 6),
              TextField(controller: _nameCtrl, decoration: const InputDecoration(hintText: 'e.g. Simple Cross-Exchange')),
              const SizedBox(height: AppSpacing.lg),
              _Label('Strategy type'),
              const SizedBox(height: 6),
              SegmentedControl<StrategyType>(
                segments: StrategyType.values.map((t) => Segment(t, t.label)).toList(),
                selected: _draft.type,
                onChanged: (t) => setState(() => _draft = _draft.copyWith(type: t)),
              ),
              const SizedBox(height: AppSpacing.lg),
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
              const SizedBox(height: AppSpacing.md),
              Text(_draft.mode.description, style: theme.textTheme.bodySmall!.copyWith(color: theme.textMuted)),
              const SizedBox(height: AppSpacing.xl),
              Row(
                children: [
                  Expanded(child: _LabeledField(label: 'Min. profit (USD)', controller: _minProfitCtrl, prefix: '\$')),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(child: _LabeledField(label: 'Max trade (USD)', controller: _maxTradeCtrl, prefix: '\$')),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              _LabeledField(label: 'Stop-loss daily (USD)', controller: _stopLossCtrl, prefix: '\$'),
              const SizedBox(height: AppSpacing.xl),
              _Label('AI aggressiveness'),
              const SizedBox(height: 6),
              SegmentedControl<Aggressiveness>(
                segments: Aggressiveness.values.map((a) => Segment(a, a.label)).toList(),
                selected: _draft.aggressiveness,
                onChanged: (a) => setState(() => _draft = _draft.copyWith(aggressiveness: a)),
              ),
              const SizedBox(height: AppSpacing.xl),
              _Label('Custom LLM instructions'),
              const SizedBox(height: 6),
              TextField(
                controller: _instructionsCtrl,
                maxLines: 4,
                decoration: const InputDecoration(hintText: 'Steer the AI\u2019s reasoning for this strategy\u2026'),
              ),
              const SizedBox(height: AppSpacing.xxl),
              Row(
                children: [
                  if (widget.existing != null)
                    OutlinedButton(onPressed: _delete, style: OutlinedButton.styleFrom(foregroundColor: theme.danger, side: BorderSide(color: theme.danger)), child: const Text('Delete'))
                  else
                    const Spacer(),
                  const Spacer(),
                  OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                  const SizedBox(width: AppSpacing.md),
                  FilledButton(onPressed: _save, child: const Text('Save')),
                ],
              ),
            ],
          ),
        );
      },
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