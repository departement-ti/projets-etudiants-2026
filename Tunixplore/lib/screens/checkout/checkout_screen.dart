import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../data/mock_data.dart';
import '../../models/models.dart';
import '../../widgets/common/common_widgets.dart';

class CheckoutScreen extends StatefulWidget {
  final String eventId;
  final int participants;

  const CheckoutScreen({
    super.key,
    required this.eventId,
    required this.participants,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  int _selectedPayment = 0; // 0=card, 1=mobile, 2=cash
  bool _isLoading = false;
  bool _saveCard = false;

  final _cardNumberCtrl = TextEditingController(text: '•••• •••• •••• 4242');
  final _cardNameCtrl = TextEditingController(text: 'Yasmine Ben Ali');
  final _expiryCtrl = TextEditingController(text: '08/27');
  final _cvvCtrl = TextEditingController(text: '•••');
  final _promoCtrl = TextEditingController();
  bool _promoApplied = false;

  EventModel get _event => MockData.events.firstWhere(
    (e) => e.id == widget.eventId,
    orElse: () => MockData.events.first,
  );

  int get _unitPrice =>
      int.tryParse(_event.price.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
  int get _subtotal => _unitPrice * widget.participants;
  int get _discount => _promoApplied ? (_subtotal * 0.10).round() : 0;
  int get _serviceFee => (_subtotal * 0.05).round();
  int get _total => _subtotal - _discount + _serviceFee;

  final _paymentMethods = [
    {
      'icon': Iconsax.card,
      'label': 'Carte bancaire',
      'sub': 'Visa / Mastercard',
    },
    {'icon': Iconsax.mobile, 'label': 'Paiement mobile', 'sub': 'D17 / Flouci'},
    {
      'icon': Iconsax.money,
      'label': 'Paiement sur place',
      'sub': 'Espèces à l\'arrivée',
    },
  ];

  @override
  void dispose() {
    _cardNumberCtrl.dispose();
    _cardNameCtrl.dispose();
    _expiryCtrl.dispose();
    _cvvCtrl.dispose();
    _promoCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final event = _event;
    final isFree = event.price == 'Gratuit';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Paiement'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppConstants.pagePadding,
          8,
          AppConstants.pagePadding,
          120,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Event summary card ────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppConstants.radiusLg),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      event.imageUrl,
                      width: 70,
                      height: 70,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event.title,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Iconsax.calendar,
                              size: 12,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              event.date,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Iconsax.people,
                              size: 12,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${widget.participants} participant(s)',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Price breakdown ────────────────────────────────────────────
            const Text(
              'Récapitulatif',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppConstants.radiusLg),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  if (!isFree) ...[
                    _PriceRow(
                      label:
                          '${event.price} × ${widget.participants} personne(s)',
                      value: '$_subtotal TND',
                    ),
                    if (_promoApplied) ...[
                      const SizedBox(height: 8),
                      _PriceRow(
                        label: 'Réduction promo (10%)',
                        value: '-$_discount TND',
                        valueColor: AppColors.success,
                      ),
                    ],
                    const SizedBox(height: 8),
                    _PriceRow(
                      label: 'Frais de service (5%)',
                      value: '$_serviceFee TND',
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 10),
                      child: Divider(color: AppColors.border),
                    ),
                    _PriceRow(
                      label: 'Total',
                      value: '$_total TND',
                      isBold: true,
                    ),
                  ] else
                    const _PriceRow(
                      label: 'Entrée gratuite',
                      value: 'Gratuit',
                      isBold: true,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Promo code ─────────────────────────────────────────────────
            if (!isFree) ...[
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _promoCtrl,
                      decoration: InputDecoration(
                        hintText: 'Code promo',
                        prefixIcon: const Icon(
                          Iconsax.discount_shape,
                          size: 18,
                          color: AppColors.accent,
                        ),
                        suffixIcon: _promoApplied
                            ? const Icon(
                                Icons.check_circle_rounded,
                                color: AppColors.success,
                              )
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () {
                      if (_promoCtrl.text.toUpperCase() == 'TUNIXI10') {
                        setState(() => _promoApplied = true);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Code promo appliqué! -10% 🎉'),
                            backgroundColor: AppColors.success,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Code invalide ou expiré'),
                            backgroundColor: AppColors.error,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 16,
                      ),
                    ),
                    child: const Text('Appliquer'),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Essayez le code TUNIXI10 pour -10%',
                style: TextStyle(fontSize: 11, color: AppColors.textHint),
              ),
              const SizedBox(height: 20),
            ],

            // ── Payment method ─────────────────────────────────────────────
            if (!isFree) ...[
              const Text(
                'Mode de paiement',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              ...List.generate(_paymentMethods.length, (i) {
                final m = _paymentMethods[i];
                final sel = _selectedPayment == i;
                return GestureDetector(
                  onTap: () => setState(() => _selectedPayment = i),
                  child: AnimatedContainer(
                    duration: AppConstants.animFast,
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: sel
                          ? AppColors.accent.withOpacity(0.05)
                          : AppColors.surface,
                      borderRadius: BorderRadius.circular(
                        AppConstants.radiusLg,
                      ),
                      border: Border.all(
                        color: sel ? AppColors.accent : AppColors.border,
                        width: sel ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: sel
                                ? AppColors.accent.withOpacity(0.12)
                                : AppColors.surfaceVariant,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            m['icon'] as IconData,
                            color: sel
                                ? AppColors.accent
                                : AppColors.textSecondary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                m['label'] as String,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: sel
                                      ? AppColors.accent
                                      : AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                m['sub'] as String,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        AnimatedContainer(
                          duration: AppConstants.animFast,
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: sel ? AppColors.accent : Colors.transparent,
                            border: Border.all(
                              color: sel ? AppColors.accent : AppColors.border,
                              width: 2,
                            ),
                          ),
                          child: sel
                              ? const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 12,
                                )
                              : null,
                        ),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 16),

              // ── Card form (only if card selected) ─────────────────────────
              if (_selectedPayment == 0) ...[
                const Text(
                  'Détails de la carte',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppConstants.radiusLg),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      AppTextField(
                        hint: '•••• •••• •••• ••••',
                        label: 'Numéro de carte',
                        prefixIcon: Iconsax.card,
                        controller: _cardNumberCtrl,
                        keyboardType: TextInputType.number,
                        maxLines: 1,
                      ),
                      const SizedBox(height: 14),
                      AppTextField(
                        hint: 'Nom sur la carte',
                        label: 'Titulaire',
                        prefixIcon: Iconsax.user,
                        controller: _cardNameCtrl,
                        maxLines: 1,
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: AppTextField(
                              hint: 'MM/AA',
                              label: 'Expiration',
                              prefixIcon: Iconsax.calendar,
                              controller: _expiryCtrl,
                              keyboardType: TextInputType.number,
                              maxLines: 1,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: AppTextField(
                              hint: '•••',
                              label: 'CVV',
                              prefixIcon: Iconsax.lock,
                              controller: _cvvCtrl,
                              obscureText: true,
                              keyboardType: TextInputType.number,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      GestureDetector(
                        onTap: () => setState(() => _saveCard = !_saveCard),
                        child: Row(
                          children: [
                            AnimatedContainer(
                              duration: AppConstants.animFast,
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color: _saveCard
                                    ? AppColors.accent
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(5),
                                border: Border.all(
                                  color: _saveCard
                                      ? AppColors.accent
                                      : AppColors.border,
                                  width: 2,
                                ),
                              ),
                              child: _saveCard
                                  ? const Icon(
                                      Icons.check,
                                      color: Colors.white,
                                      size: 12,
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              'Enregistrer cette carte',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // ── Mobile payment info ────────────────────────────────────────
              if (_selectedPayment == 1)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppConstants.radiusLg),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Numéro de téléphone',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const TextField(
                        decoration: InputDecoration(
                          hintText: '+216 XX XXX XXX',
                          prefixIcon: Icon(Iconsax.mobile, size: 18),
                        ),
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.info.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppColors.info.withOpacity(0.2),
                          ),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Iconsax.info_circle,
                              color: AppColors.info,
                              size: 16,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Vous recevrez une notification de confirmation sur votre application D17 ou Flouci.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

              // ── Cash payment info ──────────────────────────────────────────
              if (_selectedPayment == 2)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(AppConstants.radiusLg),
                    border: Border.all(
                      color: AppColors.warning.withOpacity(0.2),
                    ),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Iconsax.warning_2,
                            color: AppColors.warning,
                            size: 18,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Instructions',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.warning,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 10),
                      Text(
                        '• Votre place est réservée mais non garantie\n• Présentez-vous 30 min avant le début\n• Apportez la confirmation reçue par email\n• Le paiement se fait auprès de l\'organisateur',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          height: 1.6,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),
            ],

            // ── Security badges ────────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _SecurityBadge(
                  icon: Iconsax.shield_tick,
                  label: 'Paiement sécurisé',
                ),
                const SizedBox(width: 20),
                _SecurityBadge(icon: Iconsax.lock, label: 'SSL chiffré'),
                const SizedBox(width: 20),
                _SecurityBadge(icon: Iconsax.refresh, label: 'Remboursable'),
              ],
            ),
          ],
        ),
      ),

      // ── Bottom confirm bar ────────────────────────────────────────────────
      bottomNavigationBar: Container(
        padding: EdgeInsets.fromLTRB(
          20,
          14,
          20,
          MediaQuery.of(context).padding.bottom + 14,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, -8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isFree ? 'Inscription gratuite' : 'Total à payer',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  isFree ? 'Gratuit' : '$_total TND',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: isFree ? AppColors.success : AppColors.accent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            AppButton(
              label: isFree ? 'Confirmer l\'inscription' : 'Payer $_total TND',
              isLoading: _isLoading,
              onTap: () async {
                setState(() => _isLoading = true);
                await Future.delayed(const Duration(milliseconds: 1600));
                if (mounted) {
                  setState(() => _isLoading = false);
                  context.go('/checkout/success?eventId=${event.id}');
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ── Checkout Success Screen ────────────────────────────────────────────────────
class CheckoutSuccessScreen extends StatelessWidget {
  final String eventId;
  const CheckoutSuccessScreen({super.key, required this.eventId});

  @override
  Widget build(BuildContext context) {
    final event = MockData.events.firstWhere(
      (e) => e.id == eventId,
      orElse: () => MockData.events.first,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.pagePadding),
          child: Column(
            children: [
              const Spacer(),
              // Success animation placeholder
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.success,
                  size: 72,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Inscription confirmée!',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                'Votre place pour "${event.title}" est réservée. Vous recevrez un email de confirmation.',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),

              // Ticket preview
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppConstants.radiusXl),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        event.imageUrl,
                        height: 120,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      event.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Iconsax.calendar,
                          size: 14,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          event.date,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Icon(
                          Iconsax.location,
                          size: 14,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          event.region,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(
                          AppConstants.radiusRound,
                        ),
                      ),
                      child: const Text(
                        '✓ Réservation confirmée',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.success,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),

              // Action buttons
              AppButton(
                label: 'Voir mon billet',
                icon: Iconsax.ticket,
                onTap: () => context.go('/registration/r1'),
              ),
              const SizedBox(height: 10),
              AppButton(
                label: 'Retour à l\'accueil',
                isOutline: true,
                onTap: () => context.go('/home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────
class _PriceRow extends StatelessWidget {
  final String label, value;
  final bool isBold;
  final Color? valueColor;
  const _PriceRow({
    required this.label,
    required this.value,
    this.isBold = false,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isBold ? 15 : 13,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w400,
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isBold ? 17 : 13,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
            color:
                valueColor ??
                (isBold ? AppColors.accent : AppColors.textPrimary),
          ),
        ),
      ],
    );
  }
}

class _SecurityBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  const _SecurityBadge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.textHint),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.textHint),
        ),
      ],
    );
  }
}
