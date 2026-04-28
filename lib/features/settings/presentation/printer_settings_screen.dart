import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../features/pos/data/thermal_printer_service.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/akom_button.dart';
import '../../../shared/widgets/loading_overlay.dart';

class PrinterSettingsScreen extends ConsumerStatefulWidget {
  const PrinterSettingsScreen({super.key});

  @override
  ConsumerState<PrinterSettingsScreen> createState() =>
      _PrinterSettingsScreenState();
}

class _PrinterSettingsScreenState
    extends ConsumerState<PrinterSettingsScreen> {
  List<Printer> _devices = [];
  bool _isScanning = false;

  @override
  void initState() {
    super.initState();
    _startScan();
  }

  @override
  void dispose() {
    ref.read(thermalPrinterServiceProvider).stopScan();
    super.dispose();
  }

  Future<void> _startScan() async {
    setState(() {
      _isScanning = true;
      _devices = [];
    });
    final service = ref.read(thermalPrinterServiceProvider);
    await service.startScan();
    service.devicesStream.listen(
      (devices) {
        if (mounted) setState(() => _devices = devices);
      },
      onDone: () {
        if (mounted) setState(() => _isScanning = false);
      },
    );
    // Arrêt du scan après 12 secondes
    Future.delayed(const Duration(seconds: 12), () {
      if (mounted) setState(() => _isScanning = false);
      service.stopScan();
    });
  }

  Future<void> _connect(Printer printer) async {
    await ref.read(printerConnectionProvider.notifier).connect(printer);
    final error = ref.read(printerConnectionProvider).error;
    if (mounted && error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: AkomColors.error),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Connecté à ${printer.name ?? printer.address ?? "imprimante"}',
          ),
          backgroundColor: AkomColors.success,
        ),
      );
    }
  }

  Future<void> _disconnect() async {
    await ref.read(printerConnectionProvider.notifier).disconnect();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Imprimante déconnectée')),
      );
    }
  }

  Future<void> _testPrint(Printer printer) async {
    try {
      await ref.read(thermalPrinterServiceProvider).printTest(printer);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Impression de test envoyée'),
            backgroundColor: AkomColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur impression : $e'),
            backgroundColor: AkomColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final connectionState = ref.watch(printerConnectionProvider);

    return LoadingOverlay(
      isLoading: connectionState.isConnecting,
      message: 'Connexion en cours…',
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Imprimante Bluetooth'),
          actions: [
            if (_isScanning)
              const Padding(
                padding: EdgeInsets.all(AkomSpacing.md),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AkomColors.onPrimary,
                  ),
                ),
              )
            else
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: 'Relancer le scan',
                onPressed: _startScan,
              ),
          ],
        ),
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Imprimante connectée
              if (connectionState.isConnected) ...[
                Container(
                  margin: const EdgeInsets.all(AkomSpacing.md),
                  padding: const EdgeInsets.all(AkomSpacing.md),
                  decoration: BoxDecoration(
                    color: AkomColors.successLight,
                    borderRadius: AkomRadius.borderMd,
                    border: Border.all(color: AkomColors.success),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.print, color: AkomColors.success),
                      const SizedBox(width: AkomSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              connectionState.connectedPrinter?.name ??
                                  'Imprimante',
                              style: AkomTextStyles.titleMedium
                                  .copyWith(color: AkomColors.success),
                            ),
                            Text(
                              connectionState.connectedPrinter?.address ?? '',
                              style: AkomTextStyles.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () => _testPrint(
                          connectionState.connectedPrinter!,
                        ),
                        child: const Text('Tester'),
                      ),
                      TextButton(
                        onPressed: _disconnect,
                        child: Text(
                          'Déconnecter',
                          style: TextStyle(color: AkomColors.error),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
              ],

              // Titre liste
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AkomSpacing.md,
                  AkomSpacing.md,
                  AkomSpacing.md,
                  AkomSpacing.sm,
                ),
                child: Text(
                  _isScanning
                      ? 'Recherche d\'imprimantes Bluetooth…'
                      : 'Imprimantes disponibles',
                  style: AkomTextStyles.titleLarge,
                ),
              ),

              // Liste des appareils
              Expanded(
                child: _devices.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.bluetooth_searching,
                              size: 64,
                              color: AkomColors.onSurfaceVariant,
                            ),
                            const SizedBox(height: AkomSpacing.md),
                            Text(
                              _isScanning
                                  ? 'Recherche en cours…'
                                  : 'Aucune imprimante trouvée.\nVérifiez que le Bluetooth est activé.',
                              style: AkomTextStyles.bodyMedium.copyWith(
                                color: AkomColors.onSurfaceVariant,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            if (!_isScanning) ...[
                              const SizedBox(height: AkomSpacing.lg),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AkomSpacing.xl,
                                ),
                                child: AkomButton(
                                  label: 'Relancer le scan',
                                  icon: Icons.refresh,
                                  onPressed: _startScan,
                                ),
                              ),
                            ],
                          ],
                        ),
                      )
                    : ListView.separated(
                        itemCount: _devices.length,
                        separatorBuilder: (_, _) =>
                            const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final device = _devices[index];
                          final isConnected =
                              connectionState.connectedPrinter?.address ==
                                  device.address;
                          return ListTile(
                            leading: Icon(
                              isConnected
                                  ? Icons.print
                                  : Icons.bluetooth,
                              color: isConnected
                                  ? AkomColors.success
                                  : AkomColors.primary,
                            ),
                            title: Text(
                              device.name ?? 'Appareil inconnu',
                              style: AkomTextStyles.titleMedium,
                            ),
                            subtitle: Text(
                              device.address ?? '',
                              style: AkomTextStyles.bodySmall,
                            ),
                            trailing: isConnected
                                ? const Chip(
                                    label: Text('Connecté'),
                                    backgroundColor: AkomColors.successLight,
                                  )
                                : TextButton(
                                    onPressed: () => _connect(device),
                                    child: const Text('Connecter'),
                                  ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
