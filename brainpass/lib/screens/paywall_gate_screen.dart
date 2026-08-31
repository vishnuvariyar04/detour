// screens/paywall_gate_screen.dart
//
// The hard paywall: shown after login + onboarding until "nupo Pro" is active.
// The paywall itself is designed in the RevenueCat dashboard and rendered by
// PaywallView; RootRouter listens to SubscriptionService.hasPro and swaps this
// screen out the moment the entitlement activates. No skip.

import 'package:flutter/material.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';

import '../analytics.dart';
import '../subscription_service.dart';
import '../theme.dart';

class PaywallGateScreen extends StatefulWidget {
  const PaywallGateScreen({super.key});

  @override
  State<PaywallGateScreen> createState() => _PaywallGateScreenState();
}

class _PaywallGateScreenState extends State<PaywallGateScreen> {
  @override
  void initState() {
    super.initState();
    // The gate between a fully set-up family and a usable app. Logged from a
    // State so it counts once per showing, not once per rebuild.
    Analytics.paywallShown();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PaywallView(
                onPurchaseCompleted: (_, _) {
                  Analytics.purchaseCompleted();
                  SubscriptionService.refresh();
                },
                onRestoreCompleted: (_) {
                  Analytics.restoreCompleted();
                  SubscriptionService.refresh();
                },
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
