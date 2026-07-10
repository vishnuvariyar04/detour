// screens/paywall_gate_screen.dart
//
// The hard paywall: shown after login + onboarding until "nupo Pro" is active.
// The paywall itself is designed in the RevenueCat dashboard and rendered by
// PaywallView; RootRouter listens to SubscriptionService.hasPro and swaps this
// screen out the moment the entitlement activates. No skip.

import 'package:flutter/material.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';

import '../subscription_service.dart';
import '../theme.dart';

class PaywallGateScreen extends StatelessWidget {
  const PaywallGateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PaywallView(
                onPurchaseCompleted: (_, _) => SubscriptionService.refresh(),
                onRestoreCompleted: (_) => SubscriptionService.refresh(),
                // Hard gate: dismissing just re-checks; the router only moves
                // on when the entitlement is actually active.
                onDismiss: () => SubscriptionService.refresh(),
              ),
            ),
            TextButton(
              onPressed: SubscriptionService.restore,
              child: const Text('Restore purchases'),
            ),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }
}
