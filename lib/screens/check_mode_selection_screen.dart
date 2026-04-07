import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/selected_unit_provider.dart';
import '../theme/app_theme.dart';
import 'checkout_visitor_logs_screen.dart';
import 'create_visitor_entry_screen.dart';

class CheckModeSelectionScreen extends ConsumerWidget {
  const CheckModeSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unit = ref.watch(selectedUnitProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(
        title: Text('Unit ${unit ?? '-'}'),
        actions: [
          IconButton(
            tooltip: 'Change unit',
            icon: const Icon(Icons.swap_horiz),
            onPressed: () => ref.read(selectedUnitProvider.notifier).clearUnit(),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Choose action',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 20),
                _ActionCard(
                  title: 'Check In Visitor',
                  subtitle: 'Create a new inward visitor entry',
                  icon: Icons.login,
                  color: VmsColors.tabActiveBlue,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const CreateVisitorEntryScreen(),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                _ActionCard(
                  title: 'Check Out Visitor',
                  subtitle: 'View visitor logs and checkout status',
                  icon: Icons.logout,
                  color: VmsColors.createGreen,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const CheckoutVisitorLogsScreen(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: VmsColors.card,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: color.withValues(alpha: 0.2),
                foregroundColor: color,
                child: Icon(icon),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
