import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/app_cubit.dart';
import '../../core/domain/exchange.dart';
import '../../core/domain/llm_config.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/fmt.dart';
import '../../core/widgets/widgets.dart';

/// Settings screen — LLM config, exchanges, risk, theme. See PRD §8.6.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: BlocBuilder<AppCubit, AppState>(
          builder: (context, state) {
            return ListView(
              padding: EdgeInsets.fromLTRB(AppSpacing.screenH, AppSpacing.md, AppSpacing.screenH, AppSpacing.xxxl + 72),
              children: [
                Text('Settings', style: Theme.of(context).textTheme.displayMedium!.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: AppSpacing.xl),
                _Section(title: 'Appearance', children: [
                  _ThemeToggle(brightness: state.themeBrightness),
                ]),
                const SizedBox(height: AppSpacing.section),
                _Section(title: 'LLM Co-Pilot', children: [
                  _LlmConfigTile(config: state.llmConfig),
                ]),
                const SizedBox(height: AppSpacing.section),
                _Section(title: 'Exchanges', children: [
                  _ExchangesTile(enabledIds: state.enabledExchangeIds),
                ]),
                const SizedBox(height: AppSpacing.section),
                _Section(title: 'Risk Limits', children: [
                  _RiskTile(dailyLossCapUsd: state.dailyLossCapUsd),
                ]),
                const SizedBox(height: AppSpacing.section),
                _Section(title: 'Notifications', children: [
                  _ToggleTile(title: 'Opportunity found', subtitle: 'Alert when a new opportunity meets your threshold', defaultValue: true),
                  _ToggleTile(title: 'Trade executed', subtitle: 'Notify after every executed trade', defaultValue: true),
                  _ToggleTile(title: 'Strategy paused', subtitle: 'Notify when a strategy auto-pauses', defaultValue: true),
                  _ToggleTile(title: 'Daily summary', subtitle: 'Once-per-day performance narrative', defaultValue: false),
                ]),
                const SizedBox(height: AppSpacing.section),
                _Section(title: 'Security', children: [
                  _ToggleTile(title: 'Biometric lock', subtitle: 'Require biometrics for settings and trade execution', defaultValue: false),
                ]),
                const SizedBox(height: AppSpacing.section),
                _Section(title: 'Data', children: [
                  _ToggleTile(title: 'Crash reporting', subtitle: 'Send anonymous crash reports to Sentry', defaultValue: true),
                  _ToggleTile(title: 'Usage analytics', subtitle: 'Anonymous aggregate usage stats via PostHog', defaultValue: true),
                  _ListTile(title: 'Export trade history', subtitle: 'CSV / JSON', trailing: const Icon(Icons.chevron_right, size: 20), onTap: () {}),
                  _ListTile(title: 'Retention period', subtitle: '180 days', trailing: const Icon(Icons.chevron_right, size: 20), onTap: () {}),
                ]),
                const SizedBox(height: AppSpacing.section),
                _AboutTile(),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _Section({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: AppSpacing.xs, bottom: AppSpacing.sm),
          child: Text(title, style: theme.textTheme.labelLarge!.copyWith(color: theme.textSecondary, fontWeight: FontWeight.w600)),
        ),
        ArbitronCard(padding: EdgeInsets.zero, child: Column(children: children)),
      ],
    );
  }
}

class _ThemeToggle extends StatelessWidget {
  final String brightness;
  const _ThemeToggle({required this.brightness});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = brightness == 'dark';
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          Icon(isDark ? Icons.dark_mode_outlined : Icons.light_mode_outlined, color: theme.textSecondary, size: 22),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Theme', style: theme.textTheme.titleMedium!.copyWith(fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text('System follows your device; override below', style: theme.textTheme.bodySmall!.copyWith(color: theme.textMuted)),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          SegmentedControl<String>(
            expanded: false,
            segments: const [Segment('dark', 'Dark', icon: Icons.dark_mode), Segment('light', 'Light', icon: Icons.light_mode)],
            selected: brightness,
            onChanged: (_) => context.read<AppCubit>().toggleTheme(),
          ),
        ],
      ),
    );
  }
}

class _LlmConfigTile extends StatelessWidget {
  final LlmConfig config;
  const _LlmConfigTile({required this.config});

  @override
  Widget build(BuildContext context) {
    return _ListTile(
      title: 'LLM configuration',
      subtitle: config.configured ? '${config.model} \u00b7 ${Uri.tryParse(config.endpoint)?.host ?? config.endpoint}' : 'Not configured',
      trailing: StatusChip(label: config.configured ? 'Connected' : 'Off', tone: config.configured ? ChipTone.accent : ChipTone.neutral),
      onTap: () => _showLlmSheet(context, config),
    );
  }

  void _showLlmSheet(BuildContext context, LlmConfig existing) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _LlmConfigSheet(existing: existing),
    );
  }
}

class _LlmConfigSheet extends StatefulWidget {
  final LlmConfig existing;
  const _LlmConfigSheet({required this.existing});

  @override
  State<_LlmConfigSheet> createState() => _LlmConfigSheetState();
}

class _LlmConfigSheetState extends State<_LlmConfigSheet> {
  late final TextEditingController _endpointCtrl;
  late final TextEditingController _modelCtrl;
  late final TextEditingController _keyCtrl;

  @override
  void initState() {
    super.initState();
    _endpointCtrl = TextEditingController(text: widget.existing.endpoint);
    _modelCtrl = TextEditingController(text: widget.existing.model);
    _keyCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _endpointCtrl.dispose();
    _modelCtrl.dispose();
    _keyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
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
              Text('LLM Configuration', style: theme.textTheme.headlineSmall!.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: AppSpacing.xs),
              Text('OpenAI-compatible API. Your key stays on your device.', style: theme.textTheme.bodySmall!.copyWith(color: theme.textMuted)),
              const SizedBox(height: AppSpacing.xl),
              _Label('API endpoint'),
              const SizedBox(height: 6),
              TextField(controller: _endpointCtrl, decoration: const InputDecoration(hintText: 'https://api.openai.com/v1')),
              const SizedBox(height: AppSpacing.lg),
              _Label('Model'),
              const SizedBox(height: 6),
              TextField(controller: _modelCtrl, decoration: const InputDecoration(hintText: 'gpt-4o')),
              const SizedBox(height: AppSpacing.lg),
              _Label('API key'),
              const SizedBox(height: 6),
              TextField(controller: _keyCtrl, obscureText: true, decoration: const InputDecoration(hintText: 'sk-\u2026', suffixIcon: Icon(Icons.lock_outline, size: 18))),
              const SizedBox(height: AppSpacing.xs),
              Text('Stored in device keychain. Never transmitted to Arbitron servers.', style: theme.textTheme.bodySmall!.copyWith(color: theme.textMuted)),
              const SizedBox(height: AppSpacing.xxl),
              Row(
                children: [
                  const Spacer(),
                  OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                  const SizedBox(width: AppSpacing.md),
                  FilledButton(
                    onPressed: () {
                      final cfg = widget.existing.copyWith(
                        endpoint: _endpointCtrl.text.trim().isEmpty ? widget.existing.endpoint : _endpointCtrl.text.trim(),
                        model: _modelCtrl.text.trim().isEmpty ? widget.existing.model : _modelCtrl.text.trim(),
                        configured: true,
                      );
                      context.read<AppCubit>().updateLlmConfig(cfg);
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('LLM configuration saved'), duration: Duration(seconds: 2)));
                    },
                    child: const Text('Save'),
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

class _ExchangesTile extends StatelessWidget {
  final List<String> enabledIds;
  const _ExchangesTile({required this.enabledIds});

  @override
  Widget build(BuildContext context) {
    final cexs = ExchangeCatalog.all.where((e) => e.kind == ExchangeKind.cex).toList();
    final dexs = ExchangeCatalog.all.where((e) => e.kind == ExchangeKind.dex).toList();

    return _ListTile(
      title: 'Exchanges & DEXs',
      subtitle: '${enabledIds.length} of ${ExchangeCatalog.all.length} enabled',
      trailing: const Icon(Icons.chevron_right, size: 20),
      onTap: () => _showSheet(context, cexs, dexs, enabledIds),
    );
  }

  void _showSheet(BuildContext context, List<Exchange> cexs, List<Exchange> dexs, List<String> enabled) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetCtx) {
        return BlocBuilder<AppCubit, AppState>(
          bloc: context.read<AppCubit>(),
          buildWhen: (a, b) => a.enabledExchangeIds != b.enabledExchangeIds,
          builder: (bc, state) {
            final theme = Theme.of(bc);
            final en = state.enabledExchangeIds;
            Widget group(String label, List<Exchange> list) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(padding: const EdgeInsets.only(top: AppSpacing.lg, bottom: AppSpacing.sm), child: Text(label, style: theme.textTheme.labelLarge!.copyWith(color: theme.textSecondary, fontWeight: FontWeight.w600))),
                  ...list.map((e) => _ExchangeRow(exchange: e, enabled: en.contains(e.id))),
                ],
              );
            }
            return DraggableScrollableSheet(
              initialChildSize: 0.9,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              expand: false,
              builder: (context, sc) {
                return Container(
                  color: theme.surfaceOverlay,
                  child: ListView(
                    controller: sc,
                    padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.xl, AppSpacing.xl, AppSpacing.xxxl),
                    children: [
                      Center(child: Container(width: 32, height: 4, decoration: BoxDecoration(color: theme.borderStrong, borderRadius: BorderRadius.circular(2)))),
                      const SizedBox(height: AppSpacing.xl),
                      Text('Exchanges & DEXs', style: theme.textTheme.headlineSmall!.copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(height: AppSpacing.xs),
                      Text('Enable the exchanges you want scanned. Each requires its own API credentials.', style: theme.textTheme.bodySmall!.copyWith(color: theme.textMuted)),
                      group('Centralized (CEX)', cexs),
                      group('Decentralized (DEX)', dexs),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

class _ExchangeRow extends StatelessWidget {
  final Exchange exchange;
  final bool enabled;
  const _ExchangeRow({required this.exchange, required this.enabled});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cubit = context.read<AppCubit>();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          ExchangeAvatar(name: exchange.name, size: 36),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(exchange.name, style: theme.textTheme.titleMedium!.copyWith(fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text('${exchange.region} \u00b7 maker ${Fmt.pctRaw(exchange.makerFee * 100, decimals: 2)} \u00b7 taker ${Fmt.pctRaw(exchange.takerFee * 100, decimals: 2)}',
                    style: theme.textTheme.bodySmall!.copyWith(color: theme.textMuted)),
              ],
            ),
          ),
          Switch(value: enabled, onChanged: (v) => cubit.setExchangeEnabled(exchange.id, v), activeColor: theme.accent),
        ],
      ),
    );
  }
}

class _RiskTile extends StatelessWidget {
  final double dailyLossCapUsd;
  const _RiskTile({required this.dailyLossCapUsd});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _ListTile(
      title: 'Global daily loss cap',
      subtitle: 'Auto-pauses all autonomous strategies if hit',
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(color: theme.warningDim, borderRadius: BorderRadius.circular(6)),
        child: Text(Fmt.usd(dailyLossCapUsd, decimals: 0),
            style: theme.textTheme.labelMedium!.copyWith(color: theme.warning, fontWeight: FontWeight.w600)),
      ),
      onTap: () => _showSheet(context, dailyLossCapUsd),
    );
  }

  void _showSheet(BuildContext context, double current) {
    double value = current;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetCtx) {
        final theme = Theme.of(sheetCtx);
        return StatefulBuilder(
          builder: (sbCtx, setState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.xl, AppSpacing.xl, AppSpacing.xxl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(child: Container(width: 32, height: 4, decoration: BoxDecoration(color: theme.borderStrong, borderRadius: BorderRadius.circular(2)))),
                    const SizedBox(height: AppSpacing.xl),
                    Text('Daily Loss Cap', style: theme.textTheme.headlineSmall!.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: AppSpacing.md),
                    Text('When aggregate daily loss exceeds this amount, all autonomous strategies auto-pause. Manual and semi-auto trades are unaffected.',
                        style: theme.textTheme.bodyMedium!.copyWith(color: theme.textSecondary, height: 1.5)),
                    const SizedBox(height: AppSpacing.xl),
                    Center(child: Text(Fmt.usd(value, decimals: 0), style: theme.textTheme.displayMedium!.copyWith(fontWeight: FontWeight.w700, color: theme.warning))),
                    Slider(
                      value: value,
                      min: 50, max: 2000, divisions: 39,
                      onChanged: (v) => setState(() => value = v),
                      activeColor: theme.warning,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [Text('\$50', style: theme.textTheme.labelSmall!.copyWith(color: theme.textMuted)), Text('\$2000', style: theme.textTheme.labelSmall!.copyWith(color: theme.textMuted))],
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Row(
                      children: [
                        const Spacer(),
                        OutlinedButton(onPressed: () => Navigator.pop(sbCtx), child: const Text('Cancel')),
                        const SizedBox(width: AppSpacing.md),
                        FilledButton(
                          onPressed: () { context.read<AppCubit>().setDailyLossCap(value); Navigator.pop(sbCtx); },
                          child: const Text('Save'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _ToggleTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool defaultValue;
  const _ToggleTile({required this.title, this.subtitle, required this.defaultValue});

  @override
  Widget build(BuildContext context) {
    return _ToggleRow(title: title, subtitle: subtitle, defaultValue: defaultValue);
  }
}

class _ToggleRow extends StatefulWidget {
  final String title;
  final String? subtitle;
  final bool defaultValue;
  const _ToggleRow({required this.title, this.subtitle, required this.defaultValue});

  @override
  State<_ToggleRow> createState() => _ToggleRowState();
}

class _ToggleRowState extends State<_ToggleRow> {
  late bool _on;
  @override
  void initState() { super.initState(); _on = widget.defaultValue; }
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.title, style: theme.textTheme.titleMedium!.copyWith(fontWeight: FontWeight.w500)),
                if (widget.subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(widget.subtitle!, style: theme.textTheme.bodySmall!.copyWith(color: theme.textMuted)),
                ],
              ],
            ),
          ),
          Switch(value: _on, onChanged: (v) => setState(() => _on = v), activeColor: theme.accent),
        ],
      ),
    );
  }
}

class _ListTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  const _ListTile({required this.title, this.subtitle, this.trailing, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.titleMedium!.copyWith(fontWeight: FontWeight.w500)),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle!, style: theme.textTheme.bodySmall!.copyWith(color: theme.textMuted)),
                  ],
                ],
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}

class _AboutTile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ArbitronCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(color: theme.accentDim, borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.auto_awesome, color: AppColors.accent, size: 22),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Arbitron', style: theme.textTheme.titleLarge!.copyWith(fontWeight: FontWeight.w700)),
                    Text('AI-Powered Crypto Arbitrage Platform', style: theme.textTheme.bodySmall!.copyWith(color: theme.textMuted)),
                  ],
                ),
              ),
              const Spacer(),
              Text('v1.0.0', style: theme.textTheme.labelMedium!.copyWith(color: theme.textMuted)),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Divider(height: 1, color: theme.borderSubtle),
          const SizedBox(height: AppSpacing.md),
          Text('Cryptocurrency trading involves significant risk of loss. AI analysis is not financial advice. Past performance does not predict future results.',
              style: theme.textTheme.bodySmall!.copyWith(color: theme.textMuted, height: 1.5)),
        ],
      ),
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