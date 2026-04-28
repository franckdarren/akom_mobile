import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../../core/storage/local_storage.dart';
import '../../../features/auth/data/auth_provider.dart';
import '../../../features/pos/data/thermal_printer_service.dart';
import '../../../shared/theme/app_theme.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storage = ref.watch(localStorageProvider);
    final user = sb.Supabase.instance.client.auth.currentUser;
    final printerState = ref.watch(printerConnectionProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Paramètres')),
      body: SafeArea(
        child: ListView(
          children: [
            // ── Compte ──────────────────────────────────────────────────────
            _SectionHeader(label: 'Compte'),
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('Email'),
              subtitle: Text(user?.email ?? '—'),
            ),
            const Divider(height: 1),

            // ── Restaurant ──────────────────────────────────────────────────
            _SectionHeader(label: 'Restaurant'),
            ListTile(
              leading: const Icon(Icons.store_outlined),
              title: const Text('Restaurant actif'),
              subtitle: Text(storage.restaurantName ?? '—'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                await ref
                    .read(localStorageProvider)
                    .saveRestaurant(id: '', name: '');
                if (context.mounted) context.go('/restaurants');
              },
            ),
            const Divider(height: 1),

            // ── Impression ──────────────────────────────────────────────────
            _SectionHeader(label: 'Impression'),
            ListTile(
              leading: Icon(
                Icons.print_outlined,
                color: printerState.isConnected
                    ? AkomColors.success
                    : AkomColors.onSurfaceVariant,
              ),
              title: const Text('Imprimante Bluetooth'),
              subtitle: Text(
                printerState.isConnected
                    ? printerState.connectedPrinter?.name ?? 'Connectée'
                    : 'Aucune imprimante connectée',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/settings/printer'),
            ),
            const Divider(height: 1),

            // ── Déconnexion ─────────────────────────────────────────────────
            const SizedBox(height: AkomSpacing.md),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AkomSpacing.md),
              child: OutlinedButton.icon(
                icon: const Icon(Icons.logout, color: AkomColors.error),
                label: const Text(
                  'Se déconnecter',
                  style: TextStyle(color: AkomColors.error),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AkomColors.error),
                ),
                onPressed: () => _signOut(context, ref),
              ),
            ),

            // ── Version ─────────────────────────────────────────────────────
            const SizedBox(height: AkomSpacing.xl),
            Center(
              child: Text(
                'Akôm Scanner v1.0.0',
                style: AkomTextStyles.bodySmall,
              ),
            ),
            const SizedBox(height: AkomSpacing.md),
          ],
        ),
      ),
    );
  }

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    await ref.read(authRepositoryProvider).signOut();
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AkomSpacing.md,
        AkomSpacing.lg,
        AkomSpacing.md,
        AkomSpacing.xs,
      ),
      child: Text(
        label.toUpperCase(),
        style: AkomTextStyles.bodySmall.copyWith(
          color: AkomColors.primary,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}
