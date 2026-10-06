// screens/paywall_screen.dart — the Nupo Pro paywall.
//
// Three pages, in the order the best trial paywalls use (Cal AI's is the
// reference):
//
//   1. Try it free   — what Nupo does (the home screen, YouTube, the lesson
//                      that opens first), "No payment due now", "Try for ₹0".
//   2. Reminder      — "We'll send you a reminder before your free trial
//                      ends". Continue asks for the notification permission
//                      the reminder needs. Skipped when no plan has a trial.
//   3. Plans         — the trial timeline (today / reminder / billing day),
//                      then the plans with Yearly on top, highlighted, and its
//                      price per week.
//
// White page, near-black type, one black button: the shop reads as a page that
// states facts. Nupo's font, owl colours and words are kept.
//
// Rules (unchanged since the iOS port):
//   • Every price comes live from the store (`priceString`,
//     `pricePerWeekString`), so it is right in every country and currency.
//   • A free trial is only advertised when the store says the plan has one,
//     and its length comes from the store too.
//   • No invented ratings or user counts.

import 'package:flutter/material.dart';
import 'package:purchases_flutter/purchases_flutter.dart'
    show Package, PackageType, PeriodUnit;
import 'package:url_launcher/url_launcher.dart';

import '../analytics.dart';
import '../subscription_service.dart';
import '../trial_reminder.dart';

/// One purchasable plan as shown on the paywall, built from a live package.
class PaywallPlan {
  final String title;
  final String price;
  final String? unit; // "/week", "/year", null for one-time
  final String? perWeek; // "₹57.50" for a yearly plan, null otherwise
  final String? saveChip;
  final bool hasTrial;
  final String? trialLabel;
  final Package package;

  const PaywallPlan({
    required this.title,
    required this.price,
    required this.package,
    this.unit,
    this.perWeek,
    this.saveChip,
    this.hasTrial = false,
    this.trialLabel,
  });

  bool get isYearly => package.packageType == PackageType.annual;
  bool get isWeekly => package.packageType == PackageType.weekly;
  bool get isLifetime => package.packageType == PackageType.lifetime;

  /// "₹2,999 per year (₹57.50/week)", the line under the buttons.
  String get priceLine {
    final per = switch (package.packageType) {
      PackageType.annual => 'per year',
      PackageType.monthly => 'per month',
      PackageType.weekly => 'per week',
      _ => 'once',
    };
    return perWeek == null ? '$price $per' : '$price $per ($perWeek/week)';
  }
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
  final days = trialDaysFor(p);
  if (days == null) return null;
  return '$days ${days == 1 ? 'day' : 'days'} free';
}

/// The plan's currency at zero: "₹2,999" -> "₹0", "US$4.99" -> "US$0".
String zeroPriceLike(String priceString) {
  final m = RegExp(r'\d[\d.,\s]*\d|\d').firstMatch(priceString);
  if (m == null) return priceString;
  return priceString.replaceRange(m.start, m.end, '0');
}

/// Terms / Privacy, the same pages the iOS paywall links to.
const String kTermsUrl = 'https://nupo.app/terms';
const String kPrivacyUrl = 'https://nupo.app/privacy';

enum _Step { intro, notify, plans }

class PaywallScreen extends StatefulWidget {
  /// Called once Premium is unlocked.
  final VoidCallback? onPurchased;
  final VoidCallback? onClose;

  /// False for the HARD paywall at the app root: no free tier to go back to.
  final bool dismissible;

  /// Where the plans come from; the store unless a test swaps it.
  @visibleForTesting
  final Future<List<Package>> Function()? loadPackages;

  const PaywallScreen({
    super.key,
    this.onPurchased,
    this.onClose,
    this.dismissible = false,
    this.loadPackages,
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

  /// Yearly if there is one: it leads every price line.
  PaywallPlan? get _leadPlan {
    for (final p in _plans) {
      if (p.isYearly) return p;
    }
    return _plans.isEmpty ? null : _plans.first;
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final packages =
        await (widget.loadPackages ?? SubscriptionService.packages)();
    if (!mounted) return;
    setState(() {
      _plans = _buildPlans(packages);
      _selected = 0; // Yearly is sorted first
      _loading = false;
    });
  }

  /// Live packages → display plans: Yearly first, then weekly, monthly,
  /// lifetime. The yearly saving is computed from the real prices.
  List<PaywallPlan> _buildPlans(List<Package> packages) {
    double? weeklyPerYear;
    for (final p in packages) {
      if (p.packageType == PackageType.weekly) {
        weeklyPerYear = p.storeProduct.price * 52;
      }
    }
    int rank(Package p) => switch (p.packageType) {
          PackageType.annual => 0,
          PackageType.weekly => 1,
          PackageType.monthly => 2,
          PackageType.lifetime => 3,
          _ => 4,
        };
    final sorted = [...packages]..sort((a, b) => rank(a).compareTo(rank(b)));
    return [
      for (final p in sorted)
        () {
          final annual = p.packageType == PackageType.annual;
          String? saveChip;
          if (annual && weeklyPerYear != null && weeklyPerYear > 0) {
            final pct =
                ((1 - (p.storeProduct.price / weeklyPerYear)) * 100).round();
            if (pct > 0) saveChip = 'Save $pct%';
          }
          return PaywallPlan(
            title: SubscriptionService.labelFor(p),
            price: p.storeProduct.priceString,
            unit: SubscriptionService.unitFor(p),
            perWeek: annual ? p.storeProduct.pricePerWeekString : null,
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
        }
        widget.onPurchased?.call();
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

  /// Page 2's button: ask for the permission the promised reminder needs,
  /// whatever the answer, then show the plans.
  Future<void> _allowReminder() async {
    if (_busy) return;
    setState(() => _busy = true);
    await TrialReminder.requestPermission();
    if (!mounted) return;
    setState(() {
      _busy = false;
      _step = _Step.plans;
    });
  }

  bool get _selectedHasTrial =>
      _plans.isNotEmpty && _plans[_selected].hasTrial;

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // ---------------------------------------------------------------------------
  // Presentation
  // ---------------------------------------------------------------------------

  static const _ink = Color(0xFF0B0B0F);
  static const _muted = Color(0xFF86868B);

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      child: KeyedSubtree(
        key: ValueKey(_step),
        child: switch (_step) {
          _Step.intro => _introPage(context),
          _Step.notify => _notifyPage(context),
          _Step.plans => _plansPage(context),
        },
      ),
    );
  }

  Widget _shell({
    required Widget body,
    required Widget cta,
    Widget? belowCta,
    bool noPaymentDue = false,
    VoidCallback? onBack,
  }) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(
              height: 48,
              child: Row(
                children: [
                  if (onBack != null)
                    _BackCircle(onTap: onBack)
                  else
                    const SizedBox(width: 60),
                  const Spacer(),
                  TextButton(
                    onPressed: _busy ? null : _restore,
                    child: const Text('Restore',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: _muted)),
                  ),
                  const SizedBox(width: 6),
                ],
              ),
            ),
            Expanded(child: body),
            if (noPaymentDue) ...[
              const _NoPaymentDueNow(),
              const SizedBox(height: 12),
            ],
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 0, 22, 0),
              child: cta,
            ),
            if (belowCta != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(26, 10, 26, 0),
                child: belowCta,
              ),
            const SizedBox(height: 12),
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
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: double.infinity,
          height: 60,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: onTap == null ? _ink.withValues(alpha: 0.35) : _ink,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Text(
            label,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 17.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.1),
          ),
        ),
      ),
    );
  }

  Widget _priceUnderCta(PaywallPlan? plan) => plan == null
      ? const SizedBox.shrink()
      : Text('Just ${plan.priceLine}',
          textAlign: TextAlign.center,
          style: const TextStyle(
              fontSize: 13.5, fontWeight: FontWeight.w600, color: _muted));

  static const _headline = TextStyle(
      fontSize: 29,
      height: 1.2,
      fontWeight: FontWeight.w900,
      letterSpacing: -0.5,
      color: _ink);

  /// Page 1 — the invitation: what Nupo does, and that starting costs nothing.
  Widget _introPage(BuildContext context) {
    final trial = _trialPlan;
    final lead = _leadPlan;
    final next = trial != null ? _Step.notify : _Step.plans;
    return _shell(
      noPaymentDue: trial != null,
      onBack: widget.dismissible
          ? (widget.onClose ?? () => Navigator.maybePop(context))
          : null,
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(28, 6, 28, 0),
            child: Text(
              'We want you to\ntry Nupo for free.',
              textAlign: TextAlign.center,
              style: _headline,
            ),
          ),
          const SizedBox(height: 14),
          const Expanded(child: _Hero()),
        ],
      ),
      cta: _blackCta(
        trial != null && lead != null
            ? 'Try for ${zeroPriceLike(lead.price)}'
            : (_loading ? 'Please wait…' : 'See plans'),
        _loading ? null : () => setState(() => _step = next),
      ),
      belowCta: _priceUnderCta(lead),
    );
  }

  /// Page 2 — the promised reminder, and the permission it needs.
  Widget _notifyPage(BuildContext context) {
    return _shell(
      noPaymentDue: true,
      onBack: () => setState(() => _step = _Step.intro),
      body: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          children: [
            SizedBox(height: 6),
            Text(
              "We'll send you a reminder\nbefore your free trial ends",
              textAlign: TextAlign.center,
              style: _headline,
            ),
            Expanded(child: Center(child: _Bell())),
          ],
        ),
      ),
      cta: _blackCta(_busy ? 'Please wait…' : 'Continue for FREE',
          _busy ? null : _allowReminder),
      belowCta: _priceUnderCta(_leadPlan),
    );
  }

  /// Page 3 — exactly what happens on which day, then the plans.
  Widget _plansPage(BuildContext context) {
    final trial = _trialPlan;
    final trialDays = trial == null ? null : trialDaysFor(trial.package);
    final sel = _plans.isEmpty ? null : _plans[_selected];
    final selDays = sel == null ? null : trialDaysFor(sel.package);
    final ctaLabel = _busy
        ? 'Please wait…'
        : (selDays != null
            ? 'Start my $selDays-day free trial'
            : 'Continue');

    return _shell(
      noPaymentDue: _selectedHasTrial,
      onBack: () => setState(
          () => _step = trial != null ? _Step.notify : _Step.intro),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _ink))
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(22, 6, 22, 12),
              child: Column(
                children: [
                  Text(
                    trialDays != null
                        ? 'Start your $trialDays-day FREE\ntrial to continue.'
                        : 'Choose your plan',
                    textAlign: TextAlign.center,
                    style: _headline,
                  ),
                  const SizedBox(height: 24),
                  if (trialDays != null) ...[
                    _TrialTimeline(days: trialDays),
                    const SizedBox(height: 22),
                  ],
                  if (_plans.isEmpty)
                    _PlansUnavailable(onRetry: _load)
                  else
                    for (int i = 0; i < _plans.length; i++) ...[
                      _PlanCard(
                        plan: _plans[i],
                        selected: _selected == i,
                        onTap: () => setState(() => _selected = i),
                      ),
                      SizedBox(height: i == 0 ? 14 : 10),
                    ],
                ],
              ),
            ),
      cta: _blackCta(ctaLabel, (_busy || _plans.isEmpty) ? null : _continue),
      belowCta: Column(
        children: [
          if (sel != null)
            Text(
              selDays != null
                  ? '$selDays days free, then ${sel.priceLine}'
                  : sel.priceLine,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w700, color: _ink),
            ),
          const SizedBox(height: 4),
          Text(
            sel?.unit == null
                ? 'One payment. Yours to keep.'
                : 'Renews automatically unless cancelled before the period '
                    'ends. Manage or cancel any time in Google Play.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 10.5, height: 1.4, color: _muted),
          ),
          const SizedBox(height: 6),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _LegalLink(label: 'Terms', url: kTermsUrl),
              Text('  ·  ', style: TextStyle(color: _muted, fontSize: 11.5)),
              _LegalLink(label: 'Privacy', url: kPrivacyUrl),
            ],
          ),
        ],
      ),
    );
  }
}

/// Page 1's picture: the home screen, an arrow from YouTube, and the lesson
/// that opens first, fading into the page at the bottom.
class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // a soft lilac glow behind the phones
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0, -0.1),
                radius: 0.75,
                colors: [
                  const Color(0xFF7C3AED).withValues(alpha: 0.10),
                  Colors.white.withValues(alpha: 0),
                ],
              ),
            ),
          ),
        ),
        ShaderMask(
          blendMode: BlendMode.dstIn,
          shaderCallback: (r) => const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, Colors.white, Color(0x00FFFFFF)],
            stops: [0, 0.78, 1],
          ).createShader(r),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Image.asset(
              'assets/paywall/hero.png',
              fit: BoxFit.contain,
              semanticLabel:
                  'YouTube opens after a short Nupo lesson',
            ),
          ),
        ),
      ],
    );
  }
}

/// Page 2's picture: a bell with one unread reminder.
class _Bell extends StatelessWidget {
  const _Bell();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 240,
      height: 240,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Container(
            width: 230,
            height: 230,
            decoration: const BoxDecoration(
                color: Color(0xFFF4F4F6), shape: BoxShape.circle),
          ),
          const Icon(Icons.notifications_rounded,
              size: 158, color: Color(0xFFD1D1D8)),
          Positioned(
            top: 38,
            right: 44,
            child: Container(
              width: 50,
              height: 50,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFFF04438),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 4),
              ),
              child: const Text('1',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900)),
            ),
          ),
        ],
      ),
    );
  }
}

class _BackCircle extends StatelessWidget {
  final VoidCallback onTap;
  const _BackCircle({required this.onTap});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(left: 14),
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
                color: Color(0xFFF4F4F6), shape: BoxShape.circle),
            child: const Icon(Icons.chevron_left_rounded,
                size: 28, color: Color(0xFF0B0B0F)),
          ),
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

/// One selectable plan. Yearly gets the badges and its price per week, so it
/// reads as the obvious choice; the others are plain rows.
class _PlanCard extends StatelessWidget {
  final PaywallPlan plan;
  final bool selected;
  final VoidCallback onTap;
  const _PlanCard(
      {required this.plan, required this.selected, required this.onTap});

  static const _ink = Color(0xFF0B0B0F);
  static const _muted = Color(0xFF86868B);
  static const _green = Color(0xFF12B76A);

  @override
  Widget build(BuildContext context) {
    final yearly = plan.isYearly;
    final sub = switch (plan.package.packageType) {
      PackageType.annual => '${plan.price} per year',
      PackageType.monthly => 'Billed monthly',
      PackageType.weekly => 'Billed weekly',
      PackageType.lifetime => 'Pay once, keep forever',
      _ => '',
    };
    // Big number on the right: per week for yearly, else the price itself.
    final big = plan.perWeek ?? plan.price;
    final bigUnit = plan.perWeek != null
        ? 'per week'
        : switch (plan.package.packageType) {
            PackageType.weekly => 'per week',
            PackageType.monthly => 'per month',
            PackageType.lifetime => 'once',
            _ => '',
          };

    return Semantics(
      button: true,
      selected: selected,
      label: '${plan.title}, ${plan.priceLine}',
      child: GestureDetector(
        onTap: onTap,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding: EdgeInsets.fromLTRB(16, yearly ? 22 : 16, 14, 16),
              decoration: BoxDecoration(
                color: yearly ? const Color(0xFFFFFBF0) : Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: selected ? _ink : const Color(0xFFE3E3E8),
                  width: selected ? 2.4 : 1.4,
                ),
              ),
              child: Row(
                children: [
                  _Radio(selected: selected),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(plan.title,
                            style: TextStyle(
                                fontSize: yearly ? 18.5 : 16.5,
                                fontWeight: FontWeight.w900,
                                color: _ink)),
                        const SizedBox(height: 2),
                        Text(sub,
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: _muted)),
                        if (plan.saveChip != null) ...[
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: _green.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(plan.saveChip!,
                                style: const TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF087443))),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(big,
                          style: TextStyle(
                              fontSize: yearly ? 22 : 17,
                              fontWeight: FontWeight.w900,
                              color: _ink)),
                      if (bigUnit.isNotEmpty)
                        Text(bigUnit,
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: _muted)),
                    ],
                  ),
                ],
              ),
            ),
            if (yearly)
              Positioned(
                top: -11,
                left: 14,
                child: Row(
                  children: [
                    const _Pill(
                        text: 'BEST VALUE',
                        bg: Color(0xFFF9C13C),
                        fg: Color(0xFF241C3B)),
                    if (plan.trialLabel != null) ...[
                      const SizedBox(width: 6),
                      _Pill(
                          text: plan.trialLabel!.toUpperCase(),
                          bg: _ink,
                          fg: Colors.white),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String text;
  final Color bg;
  final Color fg;
  const _Pill({required this.text, required this.bg, required this.fg});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
            color: bg, borderRadius: BorderRadius.circular(999)),
        child: Text(text,
            style: TextStyle(
                color: fg,
                fontSize: 10.5,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.6)),
      );
}

class _Radio extends StatelessWidget {
  final bool selected;
  const _Radio({required this.selected});

  @override
  Widget build(BuildContext context) => AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF0B0B0F) : Colors.transparent,
          shape: BoxShape.circle,
          border: Border.all(
              color:
                  selected ? const Color(0xFF0B0B0F) : const Color(0xFFD3D3D9),
              width: 1.8),
        ),
        child: selected
            ? const Icon(Icons.check_rounded, size: 17, color: Colors.white)
            : null,
      );
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
        borderRadius: BorderRadius.circular(18),
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
          Icon(Icons.check_rounded, size: 20, color: Color(0xFF0B0B0F)),
          SizedBox(width: 7),
          Text('No payment due now',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0B0B0F))),
        ],
      );
}

/// What happens, and when, computed from the store's own trial length.
class _TrialTimeline extends StatelessWidget {
  final int days;
  const _TrialTimeline({required this.days});

  static const _gold = Color(0xFFF9C13C);
  static const _ink = Color(0xFF0B0B0F);

  @override
  Widget build(BuildContext context) {
    final charge = billingStartsAt(DateTime.now(), days);
    final reminderDay = days - 1;
    return Column(
      children: [
        const _TimelineRow(
          icon: Icons.lock_open_rounded,
          tint: _gold,
          next: _gold,
          title: 'Today',
          body: 'Unlock every course. Lessons start the next time your child '
              'opens an app you picked.',
        ),
        if (reminderDay > 0)
          _TimelineRow(
            icon: Icons.notifications_rounded,
            tint: _gold,
            next: _ink,
            title: 'In $reminderDay ${reminderDay == 1 ? 'day' : 'days'} '
                '- Reminder',
            body: "We'll send you a reminder that your trial is ending soon.",
          ),
        _TimelineRow(
          icon: Icons.workspace_premium_rounded,
          tint: _ink,
          title: 'In $days ${days == 1 ? 'day' : 'days'} - Billing starts',
          body: "You'll be charged on ${formatBillingDate(charge)} unless "
              'you cancel anytime before in Google Play.',
        ),
      ],
    );
  }
}

class _TimelineRow extends StatelessWidget {
  final IconData icon;
  final Color tint;

  /// Colour the rail fades into, toward the next row; null on the last row.
  final Color? next;
  final String title;
  final String body;
  const _TimelineRow({
    required this.icon,
    required this.tint,
    required this.title,
    required this.body,
    this.next,
  });

  @override
  Widget build(BuildContext context) {
    final last = next == null;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 40,
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration:
                      BoxDecoration(color: tint, shape: BoxShape.circle),
                  child: Icon(icon,
                      size: 21,
                      color: tint == const Color(0xFFF9C13C)
                          ? const Color(0xFF241C3B)
                          : Colors.white),
                ),
                if (!last)
                  Expanded(
                    child: Container(
                      width: 8,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            tint.withValues(alpha: 0.45),
                            next!.withValues(alpha: 0.25),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: last ? 0 : 16, top: 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0B0B0F))),
                  const SizedBox(height: 2),
                  Text(body,
                      style: const TextStyle(
                          fontSize: 13.5,
                          height: 1.35,
                          fontWeight: FontWeight.w600,
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
