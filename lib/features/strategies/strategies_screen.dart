import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/app_cubit.dart';
import '../../core/domain/enums.dart';
import '../../core/domain/strategy.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/fmt.dart';
import '../../core/widgets/widgets.dart';
import 'backtest_sheet.dart';
import 'custom_strategy_builder_sheet.dart';
import 'marketplace_sheet.dart';

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
                SliverToBoxAdapter(child: Padding(padding: EdgeInsets.fromLTRB(AppSpacing.screenH, AppSpacing.md, AppSpacing.screenH, AppSpacing.sm), child: _Header())),
                if (state.strategies.isEmpty)
                  const SliverFillRemaining(hasScrollBody: false, child: EmptyState(icon: Icons.tune_outlined, title: 'No strategies configured', body: 'Add your first arbitrage strategy to begin.', actionLabel: 'Add strategy'))
                else
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(AppSpacing.screenH, 0, AppSpacing.screenH, AppSpacing.xxxl + 56),
                    sliver: SliverList.builder(
                      itemCount: state.strategies.length,
                      itemBuilder: (context, i) {
                        final s = state.strategies[i];
                        return Padding(padding: const EdgeInsets.only(bottom: AppSpacing.sm), child: _StrategyCard(strategy: s, onTap: () => _showEditor(context, s), onBacktest: () => _showBacktest(context, s)));
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
        icon: const Icon(Icons.add), label: const Text('New'),
        backgroundColor: Theme.of(context).accent, foregroundColor: Theme.of(context).bg,
      ),
    );
  }

  void _showEditor(BuildContext context, Strategy? existing) => showModalBottomSheet(context: context, isScrollControlled: true, useSafeArea: true, builder: (_) => _StrategyEditorSheet(existing: existing));
  void _showBacktest(BuildContext context, Strategy s) => showModalBottomSheet(context: context, isScrollControlled: true, useSafeArea: true, builder: (_) => BacktestSheet(strategy: s));
}

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('STRATEGIES', style: AppTypography.mono(size: 16, weight: FontWeight.w700, color: theme.textPrimary)),
        Row(mainAxisSize: MainAxisSize.min, children: [
          TextButton(onPressed: () => showModalBottomSheet(context: context, isScrollControlled: true, useSafeArea: true, builder: (_) => const MarketplaceSheet()), child: const Text('Market')),
          TextButton(onPressed: () => showModalBottomSheet(context: context, isScrollControlled: true, useSafeArea: true, builder: (_) => const CustomStrategyBuilderSheet()), child: const Text('Builder')),
        ]),
      ],
    );
  }
}

class _StrategyCard extends StatelessWidget {
  final Strategy strategy;
  final VoidCallback onTap;
  final VoidCallback onBacktest;
  const _StrategyCard({required this.strategy, required this.onTap, required this.onBacktest});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cubit = context.read<AppCubit>();
    final positive = strategy.totalPnl >= 0;
    return ArbitronPanel(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(strategy.name, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              MonoText(strategy.type.label.toUpperCase(), size: 11, weight: FontWeight.w400, color: theme.textSecondary),
            ])),
            Switch(value: strategy.enabled, onChanged: (v) => cubit.toggleStrategyEnabled(strategy.id), activeColor: theme.accent),
          ]),
          const SizedBox(height: AppSpacing.sm),
          Row(children: [
            StatusChip(label: strategy.status.label.toUpperCase(), tone: strategy.status == StrategyStatus.active ? ChipTone.accent : ChipTone.neutral),
            const SizedBox(width: 6),
            ModeChip(mode: strategy.mode, compact: true),
            const Spacer(),
            MonoText('${strategy.totalTrades}', size: 12, weight: FontWeight.w400, color: theme.textMuted),
            const SizedBox(width: 4),
            MonoText('trades', size: 11, color: theme.textMuted),
            const SizedBox(width: 12),
            MonoText(Fmt.signedUsd(strategy.totalPnl), size: 14, weight: FontWeight.w600, color: positive ? theme.success : theme.danger),
          ]),
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton.icon(onPressed: onBacktest, icon: const Icon(Icons.science_outlined, size: 14), label: const Text('Backtest')),
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
  late final TextEditingController _nameCtrl, _instructionsCtrl, _minProfitCtrl, _maxTradeCtrl, _stopLossCtrl;

  @override
  void initState() {
    super.initState();
    _draft = widget.existing ?? const Strategy(id: 'strat_new', name: 'New Strategy', type: StrategyType.simpleCrossExchange, enabled: true);
    _nameCtrl = TextEditingController(text: _draft.name);
    _instructionsCtrl = TextEditingController(text: _draft.customInstructions);
    _minProfitCtrl = TextEditingController(text: _draft.minProfitUsd.toStringAsFixed(0));
    _maxTradeCtrl = TextEditingController(text: _draft.maxTradeUsd.toStringAsFixed(0));
    _stopLossCtrl = TextEditingController(text: _draft.stopLossDailyUsd.toStringAsFixed(0));
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _instructionsCtrl.dispose(); _minProfitCtrl.dispose(); _maxTradeCtrl.dispose(); _stopLossCtrl.dispose();
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
    if (widget.existing == null) cubit.addStrategy(updated.copyWith(id: 'strat_${DateTime.now().millisecondsSinceEpoch}'));
    else cubit.updateStrategy(updated);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DraggableScrollableSheet(initialChildSize: 0.92, minChildSize: 0.5, maxChildSize: 0.95, expand: false, builder: (context, sc) {
      return Container(color: theme.surfaceOverlay, child: ListView(controller: sc, padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.xl, AppSpacing.xl, AppSpacing.xxxl), children: [
        Center(child: Container(width: 32, height: 4, decoration: BoxDecoration(color: theme.borderStrong, borderRadius: BorderRadius.circular(2)))),
        const SizedBox(height: AppSpacing.xl),
        Text(widget.existing == null ? 'New Strategy' : 'Edit Strategy', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: AppSpacing.xl),
        _Lbl('NAME'), const SizedBox(height: 6), TextField(controller: _nameCtrl),
        const SizedBox(height: AppSpacing.lg),
        _Lbl('TYPE'), const SizedBox(height: 6),
        SegmentedControl<StrategyType>(segments: StrategyType.values.map((t) => Segment(t, t.label.split(' ').first.toUpperCase())).toList(), selected: _draft.type, onChanged: (t) => setState(() => _draft = _draft.copyWith(type: t))),
        const SizedBox(height: AppSpacing.lg),
        _Lbl('MODE'), const SizedBox(height: 6),
        SegmentedControl<ExecutionMode>(segments: const [Segment(ExecutionMode.manual, 'MANUAL', icon: Icons.pan_tool_outlined), Segment(ExecutionMode.semiAuto, 'SEMI', icon: Icons.timer_outlined), Segment(ExecutionMode.autonomous, 'AUTO', icon: Icons.auto_mode)], selected: _draft.mode, onChanged: (m) => setState(() => _draft = _draft.copyWith(mode: m))),
        const SizedBox(height: AppSpacing.md),
        Text(_draft.mode.description, style: theme.textTheme.bodySmall?.copyWith(color: theme.textMuted)),
        const SizedBox(height: AppSpacing.lg),
        Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_Lbl('MIN PROFIT \$'), const SizedBox(height: 6), TextField(controller: _minProfitCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true))])),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_Lbl('MAX TRADE \$'), const SizedBox(height: 6), TextField(controller: _maxTradeCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true))])),
        ]),
        const SizedBox(height: AppSpacing.lg),
        _Lbl('STOP-LOSS DAILY \$'), const SizedBox(height: 6),
        TextField(controller: _stopLossCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true)),
        const SizedBox(height: AppSpacing.lg),
        _Lbl('AI AGGRESSIVENESS'), const SizedBox(height: 6),
        SegmentedControl<Aggressiveness>(segments: Aggressiveness.values.map((a) => Segment(a, a.label.toUpperCase())).toList(), selected: _draft.aggressiveness, onChanged: (a) => setState(() => _draft = _draft.copyWith(aggressiveness: a))),
        const SizedBox(height: AppSpacing.lg),
        _Lbl('CUSTOM LLM INSTRUCTIONS'), const SizedBox(height: 6),
        TextField(controller: _instructionsCtrl, maxLines: 4, decoration: const InputDecoration(hintText: 'Steer the AI\u2019s reasoning\u2026')),
        const SizedBox(height: AppSpacing.xxl),
        Row(children: [
          if (widget.existing != null) OutlinedButton(onPressed: () { context.read<AppCubit>().removeStrategy(widget.existing!.id); Navigator.pop(context); }, style: OutlinedButton.styleFrom(foregroundColor: theme.danger), child: const Text('Delete')) else const Spacer(),
          const Spacer(),
          OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          const SizedBox(width: AppSpacing.md),
          FilledButton(onPressed: _save, child: const Text('Save')),
        ]),
      ]));
    });
  }
}

class _Lbl extends StatelessWidget {
  final String text;
  const _Lbl(this.text);
  @override
  Widget build(BuildContext context) => Text(text, style: AppTypography.mono(size: 10, weight: FontWeight.w600, color: Theme.of(context).textSecondary));
}