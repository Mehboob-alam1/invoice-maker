import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/app_strings.dart';
import '../../providers/invoice_provider.dart';

class ProPaywallScreen extends StatefulWidget {
  const ProPaywallScreen({super.key});

  @override
  State<ProPaywallScreen> createState() => _ProPaywallScreenState();
}

class _ProPaywallScreenState extends State<ProPaywallScreen> {
  bool _trialEnabled = true;
  int _selectedPlan = 0; // 0 = trial/weekly, 1 = yearly

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.extension<AppSemanticColors>()?.textMuted;
    final strings = context.l10n;
    final features = [
      strings.professionalTemplates,
      strings.unlimitedInvoices,
      strings.customizeTemplate,
      strings.vipSupport,
      strings.removeAds,
    ];

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
          child: Column(
            children: [
              Align(
                alignment: Alignment.topLeft,
                child: IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: AppColors.unlockGradient),
                          borderRadius: BorderRadius.circular(28),
                        ),
                        child: const Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 48),
                      ),
                      const SizedBox(height: 16),
                      ShaderMask(
                        shaderCallback: (bounds) =>
                            const LinearGradient(colors: AppColors.unlockGradient).createShader(bounds),
                        child: Text(
                          strings.getProAccess,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ...features.map((f) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              children: [
                                Container(
                                  width: 26,
                                  height: 26,
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.check_rounded, color: Colors.white, size: 16),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    f,
                                    style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ],
                            ),
                          )),
                      const SizedBox(height: 16),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          child: SwitchListTile(
                            title: Text(strings.trialEnabled, style: const TextStyle(fontWeight: FontWeight.w700)),
                            value: _trialEnabled,
                            onChanged: (v) => setState(() => _trialEnabled = v),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      _PlanOption(
                        title: strings.threeDayTrial,
                        subtitle: _trialEnabled ? strings.thenWeekly : strings.trialDisabled,
                        trailing: strings.free,
                        selected: _selectedPlan == 0,
                        onTap: () => setState(() => _selectedPlan = 0),
                      ),
                      const SizedBox(height: 12),
                      _PlanOption(
                        title: strings.yearly,
                        subtitle: strings.perYear,
                        trailing: 'Rs 11,100.00',
                        selected: _selectedPlan == 1,
                        onTap: () => setState(() => _selectedPlan = 1),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () {
                  context.read<InvoiceProvider>().unlockPro();
                  Navigator.of(context).pop();
                },
                child: Text(strings.continueForFree),
              ),
              const SizedBox(height: 10),
              Text(
                strings.trialDisclaimer,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(color: muted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlanOption extends StatelessWidget {
  final String title;
  final String subtitle;
  final String trailing;
  final bool selected;
  final VoidCallback onTap;

  const _PlanOption({
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.extension<AppSemanticColors>()?.textMuted;

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? theme.colorScheme.primary : (theme.extension<AppSemanticColors>()?.border ?? Colors.grey),
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: theme.textTheme.bodySmall?.copyWith(color: muted)),
                ],
              ),
            ),
            Flexible(
              child: Text(
                trailing,
                textAlign: TextAlign.end,
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
