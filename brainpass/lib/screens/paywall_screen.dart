// screens/paywall_screen.dart — Nupo Premium paywall (Android).
//
// PORTED FROM THE iOS APP (iOS-conversion/brainpass/lib/screens/paywall_screen
// .dart, "three-step trial flow in the reference style", 2026-08-24) so both
// stores sell Nupo the same way: same look, same words, same plan logic.
//
// What is different on Android:
//   • The trial reminder is scheduled by trial_reminder.dart (a local
//     notification) where iOS uses its FamilyControls bridge. Same promise,
//     same three screens.
//   • Store wording: Google account / Google Play, not Apple ID / Settings.
//
// Rules carried over from iOS:
//   • Every price comes live from `storeProduct.priceString`, so it is right
//     for every country and currency. Nothing is hardcoded.
//   • A free trial is only advertised when the store says the product has one
//     (`introductoryPrice`), and its length comes from the store too.
//   • No invented ratings or user counts.

import 'package:flutter/material.dart';
import 'package:purchases_flutter/purchases_flutter.dart'
    show Package, PackageType, PeriodUnit;
import 'package:url_launcher/url_launcher.dart';

import '../analytics.dart';
import '../subscription_service.dart';
import '../trial_reminder.dart';
import '../widgets.dart';

/// One purchasable plan as shown on the paywall, built from a live package.
class PaywallPlan {
  final String title;
  final String price;
  final String? unit; // "/week", "/year", null for one-time
  final String blurb;
  final String? badge;
  final String? saveChip;
  final bool hasTrial;
  final String? trialLabel;
  final Package package;

  const PaywallPlan({
    required this.title,
    required this.price,
    required this.blurb,
    required this.package,
    this.unit,
    this.badge,
    this.saveChip,
    this.hasTrial = false,
    this.trialLabel,
  });
}

/// Whole days of free trial on [p], or null if it has none.
int? trialDaysFor(Package p) {
  final intro = p.storeProduct.introductoryPrice;
  if (intro == null || intro.period.isEmpty) return null;
  final n = intro.periodNumberOfUnits;
  if (n <= 0) return null;
  return switch (intro.periodUnit) {
    PeriodUnit.day => n,
    PeriodUnit.week => n * 7,
    PeriodUnit.month => n * 30,
    PeriodUnit.year => n * 365,
    PeriodUnit.unknown => null,
  };
}

/// When billing starts for a trial beginning at [from].
DateTime billingStartsAt(DateTime from, int trialDays) =>
    DateTime(from.year, from.month, from.day + trialDays);

/// "9 April 2026" — never a raw ISO string in front of a parent being billed.
String formatBillingDate(DateTime d) {
  const months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];
  return '${d.day} ${months[d.month - 1]} ${d.year}';
}

/// "7 days free" / "1 week free" from the live offer, or null without one.
String? trialLabelFor(Package p) {
  final intro = p.storeProduct.introductoryPrice;
  if (intro == null || intro.period.isEmpty) return null;
  final n = intro.periodNumberOfUnits;
  if (n <= 0) return null;
  final unit = switch (intro.periodUnit) {
    PeriodUnit.day => 'day',
    PeriodUnit.week => 'week',
    PeriodUnit.month => 'month',
    PeriodUnit.year => 'year',
    PeriodUnit.unknown => '',
  };
  if (unit.isEmpty) return null;
  return '$n $unit${n == 1 ? '' : 's'} free';
}

/// Terms / Privacy, the same pages the iOS paywall links to.
const String kTermsUrl = 'https://nupo.app/terms';
const String kPrivacyUrl = 'https://nupo.app/privacy';

/// intro invites, plans sells and says exactly what happens when, notify
/// appears only AFTER a trial has started and asks for the permission that
/// lets the promised reminder arrive. Weekly and lifetime skip notify.
enum _Step { intro, plans, notify }

class PaywallScreen extends StatefulWidget {
  /// Called once Premium is unlocked.
  final VoidCallback? onPurchased;
  final VoidCallback? onClose;

  /// False for the HARD paywall at the app root: no free tier to go back to.
  final bool dismissible;

  const PaywallScreen({
    super.key,
    this.onPurchased,
    this.onClose,
    this.dismissible = false,
  });

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  int _selected = 0;
  bool _loading = true;
  bool _busy = false;
  List<PaywallPlan> _plans = const [];
  _Step _step = _Step.intro;

  /// The plan that actually carries a free trial; null makes the whole flow a
  /// plain paywall instead of promising free days that do not exist.
  PaywallPlan? get _trialPlan {
    for (final p in _plans) {
      if (p.hasTrial) return p;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final packages = await SubscriptionService.packages();
    if (!mounted) return;
    final plans = _buildPlans(packages);
    setState(() {
      _plans = plans;
      // Land on yearly: badged "Most Popular" and the one with the trial.
      final annual =
          plans.indexWhere((p) => p.package.packageType == PackageType.annual);
      _selected = annual >= 0 ? annual : 0;
      _loading = false;
    });
  }

  /// Live packages → display plans, with the yearly saving computed from the
  /// real prices rather than claimed.
  List<PaywallPlan> _buildPlans(List<Package> packages) {
    double? weeklyPerYear;
    for (final p in packages) {
      if (p.packageType == PackageType.weekly) {
        weeklyPerYear = p.storeProduct.price * 52;
      }
    }
    return [
      for (final p in packages)
        () {
          final type = p.packageType;
          String? saveChip;
          if (type == PackageType.annual &&
              weeklyPerYear != null &&
              weeklyPerYear > 0) {
            final pct =
                ((1 - (p.storeProduct.price / weeklyPerYear)) * 100).round();
            if (pct > 0) saveChip = 'Save $pct%';
          }
          return PaywallPlan(
            title: SubscriptionService.labelFor(p),
            price: p.storeProduct.priceString,
            unit: SubscriptionService.unitFor(p),
            blurb: switch (type) {
              PackageType.weekly => 'Perfect for trying out',
              PackageType.monthly => 'Flexible monthly',
              PackageType.annual => 'Best value',
              PackageType.lifetime => 'Pay once, use forever',
              _ => p.storeProduct.description,
            },
            badge: type == PackageType.annual ? 'Most Popular' : null,
            saveChip: saveChip,
            package: p,
            hasTrial: trialDaysFor(p) != null,
            trialLabel: trialLabelFor(p),
          );
        }(),
    ];
  }

  Future<void> _continue() async {
    if (_plans.isEmpty || _busy) return;
    final package = _plans[_selected].package;
    setState(() => _busy = true);
    final outcome = await SubscriptionService.purchase(package);
    if (!mounted) return;
    setState(() => _busy = false);
    switch (outcome) {
      case PurchaseOutcome.success:
        Analytics.purchaseCompleted();
        final days = trialDaysFor(package);
        if (days != null && days > 0) {
          TrialReminder.schedule(billingStartsAt(DateTime.now(), days));
          setState(() => _step = _Step.notify);
        } else {
          widget.onPurchased?.call();
        }
      case PurchaseOutcome.cancelled:
        break; // the parent backed out; not an error
      case PurchaseOutcome.failed:
        _toast("That didn't go through. Nothing was charged.");
    }
  }

  Future<void> _restore() async {
    if (_busy) return;
    setState(() => _busy = true);
    final ok = await SubscriptionService.restore();
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) {
      Analytics.restoreCompleted();
      widget.onPurchased?.call();
    } else {
      _toast('No previous purchase found on this Google account.');
    }
  }

  bool get _selectedHasTrial =>
      _plans.isNotEmpty && _plans[_selected].hasTrial;

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // ---------------------------------------------------------------------------
  // Presentation. Like iOS, this screen does NOT use Nupo's house style: a
  // white page, near-black type and one black button, so "this is the shop"
  // reads as a page that states facts. Only the words are Nupo's.
  // ---------------------------------------------------------------------------

  static const _ink = Color(0xFF0B0B0F);
  static const _muted = Color(0xFF86868B);

  @override
  Widget build(BuildContext context) => switch (_step) {
        _Step.intro => _buildIntroStep(context),
        _Step.plans => _buildPlansStep(context),
        _Step.notify => _buildNotifyStep(context),
      };

  Widget _shell({
    required BuildContext context,
    required Widget body,
    required Widget cta,
    Widget? belowCta,
    bool noPaymentDue = false,
    bool showRestore = true,
    VoidCallback? onBack,
  }) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(
              height: 44,
              child: Row(
                children: [
                  if (onBack != null)
                    _TopChevron(onTap: onBack)
                  else
                    const SizedBox(width: 52),
                  const Spacer(),
                  if (showRestore)
                    TextButton(
                      onPressed: _busy ? null : _restore,
                      child: const Text('Restore',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: _muted)),
                    )
                  else
                    const SizedBox(width: 52),
                ],
              ),
            ),
            Expanded(child: body),
            if (noPaymentDue) ...[
              const _NoPaymentDueNow(),
              const SizedBox(height: 12),
            ],
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 0, 22, 6),
              child: cta,
            ),
            if (belowCta != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 6, 22, 0),
                child: belowCta,
              ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _blackCta(String label, VoidCallback? onTap) {
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          height: 58,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: onTap == null ? _ink.withValues(alpha: 0.35) : _ink,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            label,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.1),
          ),
        ),
      ),
    );
  }

  static TextStyle get _headline => const TextStyle(
      fontSize: 27,
      height: 1.24,
      fontWeight: FontWeight.w800,
      letterSpacing: -0.4,
      color: _ink);

  /// Step 1 — the invitation. One idea only: starting costs nothing.
  Widget _buildIntroStep(BuildContext context) {
    final trial = _trialPlan;
    return _shell(
      context: context,
      noPaymentDue: trial != null,
      onBack: widget.dismissible
          ? (widget.onClose ?? () => Navigator.maybePop(context))
          : null,
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(26, 4, 26, 8),
        child: ConstrainedBox(
          constraints: BoxConstraints(
              minHeight: MediaQuery.sizeOf(context).height * 0.66),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                trial != null
                    ? 'We want you to\ntry Nupo for free'
                    : 'Unlock everything\nin Nupo',
                textAlign: TextAlign.center,
                style: _headline,
              ),
              const SizedBox(height: 34),
              const HaloMascot('assets/nupo/wave.png', size: 170),
              const SizedBox(height: 34),
              Text(
                trial != null
                    ? 'A few questions before the apps they love. '
                        'Set it up in two minutes.'
                    : 'A few questions before the apps they love.',
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontSize: 15, height: 1.5, color: _muted),
              ),
            ],
          ),
        ),
      ),
      cta: _blackCta(trial != null ? 'Try for free' : 'See plans',
          () => setState(() => _step = _Step.plans)),
      belowCta: trial == null
          ? null
          : Text('Just ${trial.price}${trial.unit ?? ''}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12.5, color: _muted)),
    );
  }

  /// Step 3 — reached only after a trial has started. The reminder it describes
  /// is already scheduled; this asks for permission to deliver it.
  Widget _buildNotifyStep(BuildContext context) {
    Future<void> finish() async {
      if (_busy) return;
      setState(() => _busy = true);
      await TrialReminder.requestPermission();
      if (!mounted) return;
      setState(() => _busy = false);
      widget.onPurchased?.call();
    }

    return _shell(
      context: context,
      showRestore: false,
      noPaymentDue: true,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 26),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("We'll send you\na reminder before\nyour free trial ends",
                textAlign: TextAlign.center, style: _headline),
            const SizedBox(height: 44),
            Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.notifications_rounded,
                    size: 128, color: Color(0xFFE3E3E8)),
                Positioned(
                  top: -2,
                  right: -6,
                  child: Container(
                    width: 46,
                    height: 46,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                        color: Color(0xFFE5342B), shape: BoxShape.circle),
                    child: const Text('1',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w800)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 44),
            const Text(
              'One notification, the day before billing starts. '
              'Nothing else — Nupo never sends marketing.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14.5, height: 1.5, color: _muted),
            ),
          ],
        ),
      ),
      cta: _blackCta(_busy ? 'Please wait…' : 'Continue for FREE',
          _busy ? null : finish),
    );
  }

  /// Step 2 — the plans, and exactly what happens on which day.
  Widget _buildPlansStep(BuildContext context) {
    final trial = _trialPlan;
    final trialDays = trial == null ? null : trialDaysFor(trial.package);
    final ctaLabel = _busy
        ? 'Please wait…'
        : (_selectedHasTrial && trialDays != null
            ? 'Start my $trialDays-day free trial'
            : 'Continue');
    final sel = _plans.isEmpty ? null : _plans[_selected];

    return _shell(
      context: context,
      noPaymentDue: _selectedHasTrial,
      onBack: () => setState(() => _step = _Step.intro),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _ink))
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(22, 4, 22, 8),
              child: Column(
                children: [
                  Text(
                    trialDays != null
                        ? 'Start your $trialDays-day FREE\ntrial to continue.'
                        : 'Choose your plan',
                    textAlign: TextAlign.center,
                    style: _headline,
                  ),
                  const SizedBox(height: 26),
                  if (trialDays != null) ...[
                    _TrialTimeline(days: trialDays),
                    const SizedBox(height: 26),
                  ],
                  if (_plans.isEmpty)
                    _PlansUnavailable(onRetry: _load)
                  else
                    for (int i = 0; i < _plans.length; i++) ...[
                      _PlanRow(
                        plan: _plans[i],
                        selected: _selected == i,
                        onTap: () => setState(() => _selected = i),
                      ),
                      if (i != _plans.length - 1) const SizedBox(height: 10),
                    ],
                ],
              ),
            ),
      cta: _blackCta(ctaLabel, (_busy || _plans.isEmpty) ? null : _continue),
      belowCta: Column(
        children: [
          const SizedBox(height: 2),
          Text(
            (_selectedHasTrial && trialDays != null && sel != null
                    ? '$trialDays days free, then ${sel.price}${sel.unit ?? ''}. '
                    : '') +
                (sel?.unit == null
                    ? 'One payment. Yours to keep.'
                    : 'Renews automatically unless cancelled before the '
                        'period ends. Manage or cancel in Google Play.'),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 10.5, height: 1.4, color: _muted),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const _LegalLink(label: 'Terms', url: kTermsUrl),
              const Text(' · ',
                  style: TextStyle(color: _muted, fontSize: 11.5)),
              const _LegalLink(label: 'Privacy', url: kPrivacyUrl),
              const Text(' · ',
                  style: TextStyle(color: _muted, fontSize: 11.5)),
              GestureDetector(
                onTap: _busy ? null : _restore,
                child: const Text('Restore',
                    style: TextStyle(
                        fontSize: 11.5,
                        color: _muted,
                        decoration: TextDecoration.underline)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TopChevron extends StatelessWidget {
  final VoidCallback onTap;
  const _TopChevron({required this.onTap});

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 52,
        child: IconButton(
          onPressed: onTap,
          icon: const Icon(Icons.chevron_left_rounded,
              size: 30, color: Color(0xFF0B0B0F)),
        ),
      );
}

class _LegalLink extends StatelessWidget {
  final String label;
  final String url;
  const _LegalLink({required this.label, required this.url});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: () =>
            launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
        child: Text(label,
            style: const TextStyle(
                fontSize: 11.5,
                color: Color(0xFF86868B),
                decoration: TextDecoration.underline)),
      );
}

/// One selectable plan, full width because Nupo sells three.
class _PlanRow extends StatelessWidget {
  final PaywallPlan plan;
  final bool selected;
  final VoidCallback onTap;
  const _PlanRow(
      {required this.plan, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    const ink = Color(0xFF0B0B0F);
    const muted = Color(0xFF86868B);
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 14, 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: selected ? ink : const Color(0xFFE3E3E8),
                  width: selected ? 2 : 1.4),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(plan.title,
                          style: const TextStyle(
                              fontSize: 16.5,
                              fontWeight: FontWeight.w800,
                              color: ink)),
                      const SizedBox(height: 3),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(plan.price,
                              style: const TextStyle(
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.w700,
                                  color: ink)),
                          if (plan.unit != null)
                            Text(plan.unit!,
                                style: const TextStyle(
                                    fontSize: 12.5, color: muted)),
                          if (plan.saveChip != null) ...[
                            const SizedBox(width: 8),
                            Text(plan.saveChip!,
                                style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF1E9E5A))),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: selected ? ink : Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: selected ? ink : const Color(0xFFD3D3D9),
                        width: 1.8),
                  ),
                  child: selected
                      ? const Icon(Icons.check_rounded,
                          size: 16, color: Colors.white)
                      : null,
                ),
              ],
            ),
          ),
          if (plan.trialLabel != null)
            Positioned(
              top: -9,
              right: 16,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                    color: ink, borderRadius: BorderRadius.circular(999)),
                child: Text(plan.trialLabel!.toUpperCase(),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5)),
              ),
            ),
        ],
      ),
    );
  }
}

class _PlansUnavailable extends StatelessWidget {
  final VoidCallback onRetry;
  const _PlansUnavailable({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final why = SubscriptionService.lastPackagesError;
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE3E3E8), width: 1.4),
      ),
      child: Column(
        children: [
          const Icon(Icons.cloud_off_rounded,
              size: 30, color: Color(0xFF86868B)),
          const SizedBox(height: 10),
          const Text("Plans couldn't be loaded",
              style: TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0B0B0F))),
          const SizedBox(height: 6),
          const Text('Check your connection and try again.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Color(0xFF86868B))),
          // The real reason, in small print: a store misconfiguration and a
          // dead network otherwise look identical.
          if (why != null) ...[
            const SizedBox(height: 8),
            Text(why,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 10.5, height: 1.3, color: Color(0xFF86868B))),
          ],
          const SizedBox(height: 14),
          GestureDetector(
            onTap: onRetry,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 22, vertical: 11),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: const Color(0xFF0B0B0F), width: 1.5),
              ),
              child: const Text('Try again',
                  style: TextStyle(
                      fontWeight: FontWeight.w700, color: Color(0xFF0B0B0F))),
            ),
          ),
        ],
      ),
    );
  }
}

/// Drawn only where it is literally true: the selected plan has a trial.
class _NoPaymentDueNow extends StatelessWidget {
  const _NoPaymentDueNow();

  @override
  Widget build(BuildContext context) => const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_rounded, size: 18, color: Color(0xFF0B0B0F)),
          SizedBox(width: 7),
          Text('No payment due now',
              style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0B0B0F))),
        ],
      );
}

/// What happens, and when, computed from the store's own trial length.
class _TrialTimeline extends StatelessWidget {
  final int days;
  const _TrialTimeline({required this.days});

  @override
  Widget build(BuildContext context) {
    final charge = billingStartsAt(DateTime.now(), days);
    final reminderDay = days - 1;
    return Column(
      children: [
        const _TimelineRow(
          icon: Icons.lock_open_rounded,
          tint: Color(0xFFF0A81E),
          title: 'Today',
          body: 'Everything unlocks. Pick the apps and set the rules.',
          showLine: true,
        ),
        if (reminderDay > 0)
          _TimelineRow(
            icon: Icons.notifications_rounded,
            tint: const Color(0xFFF0A81E),
            title: reminderDay == 1
                ? 'In 1 day — Reminder'
                : 'In $reminderDay days — Reminder',
            body: "We'll remind you the trial is ending, if you allow "
                'notifications on the next screen.',
            showLine: true,
          ),
        _TimelineRow(
          icon: Icons.workspace_premium_rounded,
          tint: const Color(0xFF0B0B0F),
          title: days == 1
              ? 'In 1 day — Billing starts'
              : 'In $days days — Billing starts',
          body: "You'll be charged on ${formatBillingDate(charge)} "
              'unless you cancel in Google Play before then.',
          showLine: false,
        ),
      ],
    );
  }
}

class _TimelineRow extends StatelessWidget {
  final IconData icon;
  final Color tint;
  final String title;
  final String body;
  final bool showLine;
  const _TimelineRow({
    required this.icon,
    required this.tint,
    required this.title,
    required this.body,
    required this.showLine,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(color: tint, shape: BoxShape.circle),
                child: Icon(icon, size: 17, color: Colors.white),
              ),
              if (showLine)
                Expanded(
                  child: Container(
                    width: 3,
                    margin: const EdgeInsets.symmetric(vertical: 2),
                    color: tint.withValues(alpha: 0.30),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: showLine ? 18 : 0, top: 5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0B0B0F))),
                  const SizedBox(height: 3),
                  Text(body,
                      style: const TextStyle(
                          fontSize: 12.8,
                          height: 1.42,
                          color: Color(0xFF86868B))),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
