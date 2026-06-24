import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/app_cubit.dart';
import '../../core/domain/exchange.dart';
import '../../core/domain/llm_config.dart';
import '../../core/domain/trade.dart';
import '../../core/data/trade_exporter.dart';
import '../../core/data/tax_exporter.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/fmt.dart';
import '../../core/widgets/widgets.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: BlocBuilder<AppCubit, AppState>(
          builder: (context, state) {
            final theme = Theme.of(context);
            return ListView(
              padding: EdgeInsets.fromLTRB(AppSpacing.screenH, AppSpacing.md, AppSpacing.screenH, AppSpacing.xxxl + 56),
              children: [
                Text('SETUP', style: AppTypography.mono(size: 16, weight: FontWeight.w700, color: theme.textPrimary)),
                const SizedBox(height: AppSpacing.xl),
                _Section(title: 'APPEARANCE', children: [_ThemeToggle(brightness: state.themeBrightness)]),
                const SizedBox(height: AppSpacing.section),
                _Section(title: 'LLM CO-PILOT', children: [_LlmConfigTile(config: state.llmConfig, configured: state.llmConfigured)]),
                const SizedBox(height: AppSpacing.section),
                _Section(title: 'EXCHANGES', children: [_ExchangesTile(enabledIds: state.enabledExchangeIds)]),
                const SizedBox(height: AppSpacing.section),
                _Section(title: 'RISK LIMITS', children: [_RiskTile(dailyLossCapUsd: state.dailyLossCapUsd)]),
                const SizedBox(height: AppSpacing.section),
                _Section(title: 'NOTIFICATIONS', children: [
                  _ToggleRow(title: 'Opportunity found', subtitle: 'Alert when a new opportunity meets your threshold', on: true),
                  _ToggleRow(title: 'Trade executed', subtitle: 'Notify after every executed trade', on: true),
                  _ToggleRow(title: 'Strategy paused', subtitle: 'Notify when a strategy auto-pauses', on: true),
                  _ToggleRow(title: 'Daily summary', subtitle: 'Once-per-day performance narrative', on: false),
                ]),
                const SizedBox(height: AppSpacing.section),
                _Section(title: 'SECURITY', children: [_ToggleRow(title: 'Biometric lock', subtitle: 'Require biometrics for settings and trade execution', on: false)]),
                const SizedBox(height: AppSpacing.section),
                _Section(title: 'DATA', children: [
                  _ToggleRow(title: 'Crash reporting', subtitle: 'Anonymous crash reports to Sentry', on: true),
                  _ToggleRow(title: 'Usage analytics', subtitle: 'Anonymous usage stats via PostHog', on: true),
                  _Row(title: 'Export trade history', subtitle: 'CSV / JSON', onTap: () => _showExportSheet(context, state.trades)),
                  _Row(title: 'Retention period', subtitle: '180 days', onTap: () {}),
                ]),
                const SizedBox(height: AppSpacing.section),
                _Section(title: 'POWER USER API', children: [_ApiServerTile(running: state.apiRunning, port: state.apiPort, token: state.apiToken)]),
                const SizedBox(height: AppSpacing.section),
                _Section(title: 'TAX EXPORT', children: [_TaxExportTile(trades: state.trades)]),
                const SizedBox(height: AppSpacing.section),
                _AboutTile(),
              ],
            );
          },
        ),
      ),
    );
  }

  void _showExportSheet(BuildContext context, List<TradeRecord> trades) {
    final theme = Theme.of(context);
    showModalBottomSheet(context: context, isScrollControlled: true, useSafeArea: true, builder: (ctx) {
      return SafeArea(child: Padding(padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.xl, AppSpacing.xl, AppSpacing.xxl), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Center(child: Container(width: 32, height: 4, decoration: BoxDecoration(color: theme.borderStrong, borderRadius: BorderRadius.circular(2)))),
        const SizedBox(height: AppSpacing.xl),
        Text('Export Trade History', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        MonoText('${trades.length} trades', size: 12, color: theme.textMuted),
        const SizedBox(height: AppSpacing.xl),
        for (final fmt in ExportFormat.values)
          Padding(padding: const EdgeInsets.only(bottom: 6), child: _Row(title: fmt.label, subtitle: TradeExporter.filename(fmt), onTap: () { final content = fmt == ExportFormat.csv ? TradeExporter.toCsv(trades) : TradeExporter.toJson(trades); Navigator.pop(ctx); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${fmt.label} ready (${content.length} bytes)'), duration: const Duration(seconds: 3))); })),
      ])));
    });
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _Section({required this.title, required this.children});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: AppTypography.mono(size: 10, weight: FontWeight.w600, color: theme.textMuted)),
      const SizedBox(height: 8),
      ArbitronPanel(padding: EdgeInsets.zero, child: Column(children: children)),
    ]);
  }
}

class _Row extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  const _Row({required this.title, this.subtitle, this.trailing, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(onTap: onTap, borderRadius: BorderRadius.circular(AppRadius.sm), child: Padding(padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 12), child: Row(children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500)),
        if (subtitle != null) ...[const SizedBox(height: 2), Text(subtitle!, style: theme.textTheme.bodySmall?.copyWith(color: theme.textMuted))],
      ])),
      if (trailing != null) trailing!,
    ])));
  }
}

class _ThemeToggle extends StatelessWidget {
  final String brightness;
  const _ThemeToggle({required this.brightness});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = brightness == 'dark';
    return Padding(padding: const EdgeInsets.all(AppSpacing.lg), child: Row(children: [
      Icon(isDark ? Icons.dark_mode_outlined : Icons.light_mode_outlined, color: theme.textSecondary, size: 20),
      const SizedBox(width: AppSpacing.md),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Theme', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500)),
        const SizedBox(height: 2),
        Text('Override system default', style: theme.textTheme.bodySmall?.copyWith(color: theme.textMuted)),
      ])),
      SegmentedControl<String>(expanded: false, segments: const [Segment('dark', 'DARK'), Segment('light', 'LIGHT')], selected: brightness, onChanged: (_) => context.read<AppCubit>().toggleTheme()),
    ]));
  }
}

class _LlmConfigTile extends StatelessWidget {
  final LlmConfig config;
  final bool configured;
  const _LlmConfigTile({required this.config, required this.configured});
  @override
  Widget build(BuildContext context) {
    return _Row(
      title: 'LLM configuration',
      subtitle: configured ? '${config.model} \u00b7 ${Uri.tryParse(config.endpoint)?.host ?? config.endpoint}' : 'Not configured, add an API key',
      trailing: StatusChip(label: configured ? 'ON' : 'OFF', tone: configured ? ChipTone.accent : ChipTone.neutral),
      onTap: () => _showLlmSheet(context, config),
    );
  }

  void _showLlmSheet(BuildContext context, LlmConfig existing) {
    showModalBottomSheet(context: context, isScrollControlled: true, useSafeArea: true, builder: (_) => _LlmConfigSheet(existing: existing));
  }
}

class _LlmConfigSheet extends StatefulWidget {
  final LlmConfig existing;
  const _LlmConfigSheet({required this.existing});
  @override
  State<_LlmConfigSheet> createState() => _LlmConfigSheetState();
}

class _LlmConfigSheetState extends State<_LlmConfigSheet> {
  late final TextEditingController _endpointCtrl, _modelCtrl, _keyCtrl;
  List<String> _models = const [];
  String? _selectedModel;
  bool _fetching = false, _fetchFailed = false, _manualEntry = false;

  @override
  void initState() {
    super.initState();
    _endpointCtrl = TextEditingController(text: widget.existing.endpoint);
    _modelCtrl = TextEditingController(text: widget.existing.model);
    _keyCtrl = TextEditingController();
    _selectedModel = widget.existing.model;
  }

  @override
  void dispose() { _endpointCtrl.dispose(); _modelCtrl.dispose(); _keyCtrl.dispose(); super.dispose(); }

  Future<void> _fetchModels() async {
    final endpoint = _endpointCtrl.text.trim().isEmpty ? widget.existing.endpoint : _endpointCtrl.text.trim();
    final apiKey = _keyCtrl.text.trim().isEmpty ? null : _keyCtrl.text.trim();
    setState(() { _fetching = true; _fetchFailed = false; });
    final models = await context.read<AppCubit>().fetchLlmModels(endpoint: endpoint, apiKey: apiKey);
    if (!mounted) return;
    setState(() { _fetching = false; if (models == null || models.isEmpty) { _fetchFailed = true; _manualEntry = true; } else { _models = models; _manualEntry = false; if (!models.contains(_selectedModel)) _selectedModel = models.first; } });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DraggableScrollableSheet(initialChildSize: 0.85, minChildSize: 0.5, maxChildSize: 0.95, expand: false, builder: (context, sc) {
      return Container(color: theme.surfaceOverlay, child: ListView(controller: sc, padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.xl, AppSpacing.xl, AppSpacing.xxxl), children: [
        Center(child: Container(width: 32, height: 4, decoration: BoxDecoration(color: theme.borderStrong, borderRadius: BorderRadius.circular(2)))),
        const SizedBox(height: AppSpacing.xl),
        Text('LLM Configuration', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text('OpenAI-compatible. Key stays on device.', style: theme.textTheme.bodySmall?.copyWith(color: theme.textMuted)),
        const SizedBox(height: AppSpacing.xl),
        _Lbl('ENDPOINT'), const SizedBox(height: 6), TextField(controller: _endpointCtrl, decoration: const InputDecoration(hintText: 'https://api.openai.com/v1')),
        const SizedBox(height: AppSpacing.lg),
        _Lbl('API KEY'), const SizedBox(height: 6), TextField(controller: _keyCtrl, obscureText: true, decoration: const InputDecoration(hintText: 'sk-\u2026', suffixIcon: Icon(Icons.lock_outline, size: 16))),
        const SizedBox(height: AppSpacing.lg),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [_Lbl('MODEL'), if (_models.isNotEmpty || _manualEntry) TextButton(onPressed: () => setState(() => _manualEntry = !_manualEntry), child: Text(_manualEntry ? 'Dropdown' : 'Manual'))]),
        const SizedBox(height: 6),
        if (!_manualEntry && _models.isNotEmpty) ...[
          Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: theme.surfaceRaised, borderRadius: BorderRadius.circular(AppRadius.sm), border: Border.all(color: theme.borderSubtle, width: 1)), child: DropdownButton<String>(value: _selectedModel, isExpanded: true, underline: const SizedBox(), menuMaxHeight: 280, items: _models.map((m) => DropdownMenuItem(value: m, child: MonoText(m, size: 13))).toList(), onChanged: (v) => setState(() => _selectedModel = v))),
          const SizedBox(height: 6),
          MonoText('${_models.length} models', size: 11, color: theme.textMuted),
        ] else if (!_manualEntry && _models.isEmpty) ...[
          OutlinedButton.icon(onPressed: _fetching ? null : _fetchModels, icon: _fetching ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.download_outlined, size: 16), label: Text(_fetching ? 'Fetching' : 'Fetch available models')),
          if (_fetchFailed) ...[const SizedBox(height: 6), Text('Could not fetch. Check endpoint/key or enter manually.', style: theme.textTheme.bodySmall?.copyWith(color: theme.danger)), const SizedBox(height: 4), TextButton(onPressed: () => setState(() => _manualEntry = true), child: const Text('Enter manually'))],
        ] else ...[
          TextField(controller: _modelCtrl, decoration: const InputDecoration(hintText: 'gpt-4o')),
          const SizedBox(height: 8),
          TextButton.icon(onPressed: _fetching ? null : _fetchModels, icon: _fetching ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.refresh, size: 14), label: Text(_fetching ? 'Fetching' : 'Fetch models')),
        ],
        const SizedBox(height: AppSpacing.xxl),
        Row(children: [
          const Spacer(),
          OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          const SizedBox(width: AppSpacing.md),
          FilledButton(onPressed: () async {
            final model = _manualEntry ? (_modelCtrl.text.trim().isEmpty ? widget.existing.model : _modelCtrl.text.trim()) : (_selectedModel ?? widget.existing.model);
            final cfg = widget.existing.copyWith(endpoint: _endpointCtrl.text.trim().isEmpty ? widget.existing.endpoint : _endpointCtrl.text.trim(), model: model, configured: true);
            await context.read<AppCubit>().saveLlmConfig(cfg, _keyCtrl.text.trim().isEmpty ? null : _keyCtrl.text.trim());
            if (!context.mounted) return;
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('LLM saved'), duration: Duration(seconds: 2)));
          }, child: const Text('Save')),
        ]),
      ]));
    });
  }
}

class _ExchangesTile extends StatelessWidget {
  final List<String> enabledIds;
  const _ExchangesTile({required this.enabledIds});
  @override
  Widget build(BuildContext context) {
    return _Row(title: 'Exchanges & DEXs', subtitle: '${enabledIds.length} of ${ExchangeCatalog.all.length} enabled', trailing: const Icon(Icons.chevron_right, size: 18), onTap: () => _showSheet(context));
  }

  void _showSheet(BuildContext context) {
    showModalBottomSheet(context: context, isScrollControlled: true, useSafeArea: true, builder: (sheetCtx) {
      return BlocBuilder<AppCubit, AppState>(bloc: context.read<AppCubit>(), buildWhen: (a, b) => a.enabledExchangeIds != b.enabledExchangeIds, builder: (bc, state) {
        final theme = Theme.of(bc);
        final cexs = ExchangeCatalog.all.where((e) => e.kind == ExchangeKind.cex).toList();
        final dexs = ExchangeCatalog.all.where((e) => e.kind == ExchangeKind.dex).toList();
        Widget group(String label, List<dynamic> list) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(padding: const EdgeInsets.only(top: AppSpacing.lg, bottom: 8), child: Text(label, style: AppTypography.mono(size: 10, weight: FontWeight.w600, color: theme.textMuted))),
          ...list.map((e) => _ExchangeRow(exchange: e, enabled: state.enabledExchangeIds.contains(e.id))),
        ]);
        return DraggableScrollableSheet(initialChildSize: 0.9, minChildSize: 0.5, maxChildSize: 0.95, expand: false, builder: (context, sc) {
          return Container(color: theme.surfaceOverlay, child: ListView(controller: sc, padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.xl, AppSpacing.xl, AppSpacing.xxxl), children: [
            Center(child: Container(width: 32, height: 4, decoration: BoxDecoration(color: theme.borderStrong, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: AppSpacing.xl),
            Text('Exchanges', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text('Enable exchanges to scan. Each needs API credentials.', style: theme.textTheme.bodySmall?.copyWith(color: theme.textMuted)),
            group('CEX', cexs),
            group('DEX', dexs),
          ]));
        });
      });
    });
  }
}

class _ExchangeRow extends StatelessWidget {
  final Exchange exchange;
  final bool enabled;
  const _ExchangeRow({required this.exchange, required this.enabled});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Row(children: [
      ExchangeAvatar(name: exchange.name, size: 32),
      const SizedBox(width: AppSpacing.md),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(exchange.name, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500)),
        const SizedBox(height: 2),
        MonoText('${exchange.region} \u00b7 M ${Fmt.pctRaw(exchange.makerFee * 100, decimals: 2)} \u00b7 T ${Fmt.pctRaw(exchange.takerFee * 100, decimals: 2)}', size: 10, color: theme.textMuted),
      ])),
      Switch(value: enabled, onChanged: (v) => context.read<AppCubit>().setExchangeEnabled(exchange.id, v), activeColor: theme.accent),
    ]));
  }
}

class _RiskTile extends StatelessWidget {
  final double dailyLossCapUsd;
  const _RiskTile({required this.dailyLossCapUsd});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _Row(
      title: 'Global daily loss cap',
      subtitle: 'Auto-pauses autonomous strategies if hit',
      trailing: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: theme.warningDim, borderRadius: BorderRadius.circular(4)), child: MonoText(Fmt.usd(dailyLossCapUsd, decimals: 0), size: 12, weight: FontWeight.w600, color: theme.warning)),
      onTap: () => _showSheet(context, dailyLossCapUsd),
    );
  }

  void _showSheet(BuildContext context, double current) {
    double value = current;
    showModalBottomSheet(context: context, isScrollControlled: true, useSafeArea: true, builder: (ctx) {
      final theme = Theme.of(ctx);
      return StatefulBuilder(builder: (sbCtx, setState) {
        return SafeArea(child: Padding(padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.xl, AppSpacing.xl, AppSpacing.xxl), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 32, height: 4, decoration: BoxDecoration(color: theme.borderStrong, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: AppSpacing.xl),
          Text('Daily Loss Cap', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: AppSpacing.md),
          Text('Auto-pauses all autonomous strategies when daily loss exceeds this amount.', style: theme.textTheme.bodyMedium?.copyWith(color: theme.textSecondary, height: 1.5)),
          const SizedBox(height: AppSpacing.xl),
          Center(child: MonoText(Fmt.usd(value, decimals: 0), size: 32, weight: FontWeight.w700, color: theme.warning)),
          Slider(value: value, min: 50, max: 2000, divisions: 39, onChanged: (v) => setState(() => value = v), activeColor: theme.warning),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [MonoText('\$50', size: 11, color: theme.textMuted), MonoText('\$2000', size: 11, color: theme.textMuted)]),
          const SizedBox(height: AppSpacing.xl),
          Row(children: [
            const Spacer(),
            OutlinedButton(onPressed: () => Navigator.pop(sbCtx), child: const Text('Cancel')),
            const SizedBox(width: AppSpacing.md),
            FilledButton(onPressed: () { context.read<AppCubit>().setDailyLossCap(value); Navigator.pop(sbCtx); }, child: const Text('Save')),
          ]),
        ])));
      });
    });
  }
}

class _ToggleRow extends StatefulWidget {
  final String title;
  final String? subtitle;
  final bool on;
  const _ToggleRow({required this.title, this.subtitle, required this.on});
  @override
  State<_ToggleRow> createState() => _ToggleRowState();
}

class _ToggleRowState extends State<_ToggleRow> {
  late bool _on;
  @override
  void initState() { super.initState(); _on = widget.on; }
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 6), child: Row(children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(widget.title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500)),
        if (widget.subtitle != null) ...[const SizedBox(height: 2), Text(widget.subtitle!, style: theme.textTheme.bodySmall?.copyWith(color: theme.textMuted))],
      ])),
      Switch(value: _on, onChanged: (v) => setState(() => _on = v), activeColor: theme.accent),
    ]));
  }
}

class _ApiServerTile extends StatelessWidget {
  final bool running;
  final int? port;
  final String? token;
  const _ApiServerTile({required this.running, this.port, this.token});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cubit = context.read<AppCubit>();
    return Padding(padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Icon(Icons.api_outlined, color: theme.textSecondary, size: 20),
        const SizedBox(width: AppSpacing.md),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Local REST API', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500)),
          const SizedBox(height: 2),
          MonoText(running ? 'port $port \u00b7 localhost:$port/api/v1/status' : 'Expose data as JSON', size: 11, color: theme.textMuted),
        ])),
        Switch(value: running, onChanged: (v) async { if (v) { final tk = 'arbitron_${DateTime.now().millisecondsSinceEpoch.toRadixString(16)}'; await cubit.startApiServer(port: 8765, token: tk); } else { await cubit.stopApiServer(); } }, activeColor: theme.accent),
      ]),
      if (running && token != null) ...[
        const SizedBox(height: 8),
        Container(padding: const EdgeInsets.all(AppSpacing.md), decoration: BoxDecoration(color: theme.surfaceRaised, borderRadius: BorderRadius.circular(AppRadius.sm)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          MonoText('AUTH TOKEN', size: 9, weight: FontWeight.w600, color: theme.textMuted),
          const SizedBox(height: 4),
          SelectableText(token!, style: AppTypography.mono(size: 13, color: theme.textPrimary)),
          const SizedBox(height: 8),
          MonoText('GET /status /opportunities /trades /strategies /portfolio', size: 10, color: theme.textMuted),
        ])),
      ],
    ]));
  }
}

class _TaxExportTile extends StatelessWidget {
  final List<TradeRecord> trades;
  const _TaxExportTile({required this.trades});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final summary = TaxExporter.summary(trades);
    return Padding(padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Icon(Icons.receipt_long_outlined, color: theme.textSecondary, size: 20),
        const SizedBox(width: AppSpacing.md),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Tax Year ${summary.taxYear}', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500)),
          const SizedBox(height: 2),
          MonoText('${summary.totalTrades} trades \u00b7 net ${Fmt.signedUsd(summary.netRealized)}', size: 11, color: theme.textMuted),
        ])),
      ]),
      const SizedBox(height: 8),
      _TaxRow(label: 'Gains', value: Fmt.usd(summary.totalGains), color: theme.success),
      _TaxRow(label: 'Losses', value: Fmt.usd(summary.totalLosses), color: theme.danger),
      _TaxRow(label: 'Net', value: Fmt.signedUsd(summary.netRealized), color: summary.isNetGain ? theme.success : theme.danger, bold: true),
      _TaxRow(label: 'Short-term', value: Fmt.signedUsd(summary.shortTermGains)),
      _TaxRow(label: 'Long-term', value: Fmt.signedUsd(summary.longTermGains)),
      _TaxRow(label: 'Fees', value: Fmt.usd(summary.totalFees)),
      const SizedBox(height: 8),
      Hairline(),
      const SizedBox(height: 8),
      for (final fmt in TaxFormat.values)
        Padding(padding: const EdgeInsets.only(bottom: 4), child: _Row(title: fmt.label, subtitle: fmt.description, trailing: const Icon(Icons.download_outlined, size: 18), onTap: () {
          final content = fmt == TaxFormat.form8949 ? TaxExporter.form8949Csv(trades) : TaxExporter.taxableEventsCsv(trades);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${fmt.label} exported (${content.length} bytes)'), duration: const Duration(seconds: 3)));
        })),
    ]));
  }
}

class _TaxRow extends StatelessWidget {
  final String label, value;
  final Color? color;
  final bool bold;
  const _TaxRow({required this.label, required this.value, this.color, this.bold = false});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(padding: const EdgeInsets.symmetric(vertical: 3), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: theme.textTheme.bodyMedium?.copyWith(color: theme.textSecondary)),
      MonoText(value, size: 13, weight: bold ? FontWeight.w700 : FontWeight.w500, color: color ?? theme.textPrimary),
    ]));
  }
}

class _AboutTile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ArbitronPanel(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(width: 36, height: 36, decoration: BoxDecoration(color: theme.accentDim, borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.auto_awesome, color: AppColors.accent, size: 18)),
        const SizedBox(width: AppSpacing.md),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Arbitron', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
          MonoText('AI-Powered Crypto Arbitrage', size: 11, color: theme.textMuted),
        ])),
        MonoText('v3.0.4', size: 12, color: theme.textMuted),
      ]),
      const SizedBox(height: AppSpacing.md),
      Hairline(),
      const SizedBox(height: AppSpacing.md),
      Text('Crypto trading involves significant risk. AI analysis is not financial advice. Past performance does not predict future results.', style: theme.textTheme.bodySmall?.copyWith(color: theme.textMuted, height: 1.5)),
    ]));
  }
}

class _Lbl extends StatelessWidget {
  final String text;
  const _Lbl(this.text);
  @override
  Widget build(BuildContext context) => Text(text, style: AppTypography.mono(size: 10, weight: FontWeight.w600, color: Theme.of(context).textSecondary));
}