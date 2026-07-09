import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_exception.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/utils/fcfa_formatter.dart';
import '../../../shared/widgets/loading_overlay.dart';
import '../data/pos_providers.dart';

class PaymentScreen extends ConsumerStatefulWidget {
  const PaymentScreen({super.key});

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  String _paymentMethod = 'cash';
  final _receivedController = TextEditingController();
  bool _isProcessing = false;
  String? _error;

  @override
  void dispose() {
    _receivedController.dispose();
    super.dispose();
  }

  int? get _received => int.tryParse(_receivedController.text.replaceAll(' ', ''));

  int get _change {
    final cart = ref.read(cartProvider);
    final total = cart.fold(0, (sum, i) => sum + i.subtotal);
    final rec = _received ?? 0;
    return rec - total > 0 ? rec - total : 0;
  }

  Future<void> _confirm() async {
    final cart = ref.read(cartProvider);
    final total = cart.fold(0, (sum, i) => sum + i.subtotal);

    if (_paymentMethod == 'cash') {
      final rec = _received ?? 0;
      if (rec < total) {
        setState(() => _error = 'Le montant reçu est insuffisant.');
        return;
      }
    }

    setState(() {
      _isProcessing = true;
      _error = null;
    });

    try {
      final result = await ref.read(orderRepositoryProvider).createOrder(
            items: cart,
            totalAmount: total,
            paymentMethod: _paymentMethod,
          );

      if (!mounted) return;
      context.pushReplacement('/pos/receipt', extra: {
        'result': result,
        'items': cart,
        'paymentMethod': _paymentMethod,
        'received': _paymentMethod == 'cash' ? (_received ?? total) : null,
      });
    } on AppException catch (e) {
      setState(() {
        _isProcessing = false;
        _error = e.message;
      });
    } catch (_) {
      setState(() {
        _isProcessing = false;
        _error = 'Une erreur est survenue. Vérifiez votre connexion.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final total = cart.fold(0, (sum, i) => sum + i.subtotal);

    return Scaffold(
      appBar: AppBar(title: const Text('Paiement')),
      body: LoadingOverlay(
        isLoading: _isProcessing,
        message: 'Enregistrement de la vente…',
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AkomSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Total
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AkomSpacing.md),
                  child: Column(
                    children: [
                      Text('Total à payer',
                          style: AkomTextStyles.bodyMedium.copyWith(
                              color: AkomColors.onSurfaceVariant)),
                      const SizedBox(height: AkomSpacing.xs),
                      Text(formatFCFA(total),
                          style: AkomTextStyles.priceLarge),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AkomSpacing.lg),

              // Mode de paiement
              Text('Mode de paiement', style: AkomTextStyles.titleLarge),
              const SizedBox(height: AkomSpacing.sm),
              RadioGroup<String>(
                groupValue: _paymentMethod,
                onChanged: (v) => setState(() {
                  _paymentMethod = v!;
                  _receivedController.clear();
                  _error = null;
                }),
                child: Column(
                  children: _paymentOptions
                      .map(
                        (opt) => RadioListTile<String>(
                          value: opt.$1,
                          title: Text(opt.$2),
                          secondary: Icon(opt.$3),
                          activeColor: AkomColors.primary,
                          shape: RoundedRectangleBorder(
                              borderRadius: AkomRadius.borderMd),
                          tileColor: AkomColors.surface,
                        ),
                      )
                      .toList(),
                ),
              ),
              const SizedBox(height: AkomSpacing.lg),

              // Montant reçu (cash uniquement)
              if (_paymentMethod == 'cash') ...[
                Text('Montant reçu', style: AkomTextStyles.titleLarge),
                const SizedBox(height: AkomSpacing.sm),
                TextField(
                  controller: _receivedController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    hintText: 'Montant en FCFA',
                    suffixText: 'FCFA',
                  ),
                  onChanged: (_) => setState(() => _error = null),
                ),
                if (_received != null && _received! >= total) ...[
                  const SizedBox(height: AkomSpacing.sm),
                  Container(
                    padding: const EdgeInsets.all(AkomSpacing.md),
                    decoration: BoxDecoration(
                      color: AkomColors.successLight,
                      borderRadius: AkomRadius.borderMd,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Flexible(
                          child: Text('Monnaie à rendre',
                              style: AkomTextStyles.titleMedium),
                        ),
                        const SizedBox(width: AkomSpacing.sm),
                        Flexible(
                          child: Text(
                            formatFCFA(_change),
                            style: const TextStyle(
                                color: AkomColors.success,
                                fontSize: 20,
                                fontWeight: FontWeight.w700),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.end,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: AkomSpacing.lg),
              ],

              if (_error != null) ...[
                Container(
                  padding: const EdgeInsets.all(AkomSpacing.md),
                  decoration: BoxDecoration(
                    color: AkomColors.errorLight,
                    borderRadius: AkomRadius.borderMd,
                  ),
                  child: Text(_error!,
                      style: const TextStyle(color: AkomColors.error)),
                ),
                const SizedBox(height: AkomSpacing.md),
              ],

              ElevatedButton.icon(
                icon: const Icon(Icons.check),
                label: const Text('Confirmer le paiement'),
                onPressed: _isProcessing ? null : _confirm,
              ),
              const SizedBox(height: AkomSpacing.sm),
              OutlinedButton(
                onPressed: () => context.pop(),
                child: const Text('Retour au panier'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

const _paymentOptions = [
  ('cash', 'Espèces (Cash)', Icons.payments_outlined),
  ('airtel_money', 'Airtel Money', Icons.phone_android_outlined),
  ('moov_money', 'Moov Money', Icons.phone_android_outlined),
];
