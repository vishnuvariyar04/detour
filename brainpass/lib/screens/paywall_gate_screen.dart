// screens/paywall_gate_screen.dart
//
// The hard paywall: shown after login + onboarding until the Pro entitlement
// (SubscriptionService.entitlementId) is active. The paywall itself is the
// custom screen ported from iOS (paywall_screen.dart). RootRouter listens to
// SubscriptionService.hasPro and swaps this screen out the moment the
// entitlement activates. No skip.

import 'package:flutter/material.dart';

import '../analytics.dart';
import '../subscription_service.dart';
import 'paywall_screen.dart';

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
    // The iOS trial paywall, ported (paywall_screen.dart).
    // Hard gate, so no close button: RootRouter swaps this screen out the
    // moment the entitlement becomes active.
    return PaywallScreen(onPurchased: SubscriptionService.refresh);
  }
}
