# Nupo Pro — Paywall Design Spec

The paywall is the **hard gate** between finishing setup and using Nupo
(splash → login → onboarding → **paywall** → home). It is rendered by
RevenueCat (`PaywallView`), so this spec is the source of truth for building
the paywall in the **RevenueCat dashboard paywall editor** — not in Flutter.
Entitlement: `nupo Pro`. Packages: weekly / yearly / lifetime.

---

## 1. The moment we're designing for

The viewer is a **parent** who, seconds ago, finished investing effort:
they signed in, created a PIN, granted permissions, picked their kid's age
and apps, and set rules. They are one tap away from "my kid learns every
day without me nagging." The paywall's job is to make paying feel like the
natural last step of something they already decided — not a surprise toll.

Design consequences:

- **Continuity, not interruption.** Same colors, same owl, same warmth as
  onboarding. It must feel like Nupo's final step, not an ad.
- **Sell the outcome they just configured** ("a few minutes of real learning,
  every day"), never features or fear.
- **Voice rules apply here more than anywhere:** warm, plain,
  parent-to-parent. Never salesy, never guilt-tripping. No fake urgency, no
  countdown timers, no strikethrough games. Forbidden words: "screen time",
  "block", "limit", "control".

## 2. Visual identity (map to dashboard editor)

Use Nupo's existing tokens (`lib/theme.dart`):

| Token | Value | Paywall use |
|---|---|---|
| Primary purple | `#5A32E9` | CTA button, selected package border, links |
| Purple bright | `#7A52FF` | CTA gradient end (if editor supports gradients) |
| Sunny yellow | `#FFC117` | Badge ("Best value"), star accents, owl halo |
| Yellow soft | `#FFF4D2` | Halo circle behind the owl, badge tint |
| Yellow deep | `#B98600` | Text on soft-yellow surfaces |
| Ink | `#241E3C` | Headings, package titles, prices |
| Muted | `#74708A` | Body, captions, footer links |
| Background | `#F7F5FF` → white | Page background (soft purple wash) |
| Card | `#FFFFFF`, border `#ECE9F8`, radius 22–24 | Package cards |
| Success green | `#23B26A` | Checkmarks in the benefits list |

- **Font:** Nunito. Headings 800–900, body 600–700. (Upload Nunito in the
  dashboard's font settings; fallback: the template's rounded default.)
- **Corner language:** big radii everywhere — cards 22–24, buttons pill (29).
- **Light mode only** (the app is light-only; lock the paywall to light).
- **Imagery:** the owl mascot on its yellow halo, top center, ~120–140 px.
  Use `assets/mascot_opening.png` (the cheering pose). No stock photos.

## 3. Layout (top → bottom)

Choose the RevenueCat template closest to a **single-column, hero +
package-list + CTA** structure, then shape it to:

1. **Hero** — owl on yellow halo, centered. Small. This is a warm hello,
   not a billboard.
2. **Headline** (1 line, Nunito 900, ink):
   > **Learning they'll actually do.**
3. **Subhead** (1 line, muted, 15–16):
   > A few minutes of real learning before play — every single day.
4. **Benefits** (exactly 3, green check + short line; icon-coded like the
   app's feature rows — never more than 3):
   - ✓ Lessons pop up right inside the games they already love
   - ✓ Questions tuned to your child's age, 5–11
   - ✓ You set the apps, the questions, the minutes
5. **Package cards** (vertical stack, selectable):
   - **Yearly — pre-selected, visually dominant.** Yellow "BEST VALUE"
     badge (yellow soft bg, yellow-deep text, radius 10). Show the
     per-week equivalent as the decision helper: *"{{ price }} / year —
     about {{ sub_price_per_week }} a week."*
   - **Lifetime** — anchor above or below yearly: *"Pay once, keep it
     forever."*
   - **Weekly** — the low-commitment entry: *"Try it week by week."*
   - Selected state: 2 px purple border + soft purple fill `#F8F5FF`
     (matches `SelectCard`); unselected: white card, hairline border.
6. **CTA** — full-width purple pill (gradient `#5A32E9 → #7A52FF` if
   supported), white Nunito 800:
   - label: **Start learning** (fallback: **Unlock Nupo Pro**)
   - Below, one caption line (muted, 12.5): auto-renew disclosure, e.g.
     *"Renews automatically. Cancel anytime in Google Play."*
7. **Footer** (single quiet row, muted 12.5): `Restore purchases ·
   Terms · Privacy` — the app also renders its own Restore button under
   the PaywallView, so keep the footer visually minimal.

**What's deliberately absent:** close button (hard gate — the router only
advances on an active entitlement), timers, "% OFF" theatrics, testimonial
carousels, more than one screen of content. A parent should read everything
without scrolling on a 6" phone.

## 4. Copy bank (approved lines)

Headline options (pick one, don't stack):
1. **Learning they'll actually do.** *(primary — matches the brand tagline)*
2. Every day, a little sharper.
3. Turn their play into daily learning.

Subhead options:
1. A few minutes of real learning before play — every single day.
2. The daily learning habit that rides on the apps they already love.

CTA options: **Start learning** · Unlock Nupo Pro · Let's go

Package microcopy:
- Yearly: `BEST VALUE` badge · "about {{ per-week }} a week"
- Lifetime: "Pay once, keep it forever."
- Weekly: "Try it week by week."

Purchase states (dashboard defaults are fine, but if editable):
- Success: **"You're in! 🎉"**
- Error: "Something went wrong — nothing was charged. Please try again."
- Restore empty: "No previous purchase found for this account."

## 5. Pricing guidance (business, not layout)

- Yearly is the product we *want* chosen: price it near 8–10× weekly so the
  per-week math is an obvious win, and let lifetime anchor it from above
  (lifetime ≈ 2.5–3× yearly).
- Show full prices plainly. The only persuasion is the per-week equivalence
  on the yearly card — honest math fits the brand; discount theater doesn't.
- India launch: Play Console handles INR pricing; keep amounts
  round (₹99-style, not ₹103.47).

## 6. RevenueCat wiring (must match exactly)

| Thing | Value |
|---|---|
| Entitlement | `nupo Pro` (exact string — checked in `subscription_service.dart`) |
| Offering | `default` |
| Packages | `$rc_weekly → weekly`, `$rc_annual → yearly`, Custom/Lifetime → `lifetime` |
| Default selection | Annual |
| Paywall | attached to `default`, **published** |
| Key | `test_…` now (simulated purchases); swap to `goog_` for launch |

App-side behavior (already implemented, don't duplicate in the dashboard):
hard gate with no skip; Restore button under the view; entitlement cached
offline; purchases tied to the Firebase UID.

## 7. Accessibility & QA checklist

- [ ] Contrast: ink on white and white on purple pass AA; never yellow text
      on white (use `#B98600` on yellow-soft surfaces instead).
- [ ] Touch targets ≥ 48 dp (package cards and CTA already exceed this).
- [ ] Test on a small phone (~5.5", 720p): everything above the fold.
- [ ] Long prices (₹1,599.00/year) don't wrap or truncate on package cards.
- [ ] Simulated purchase → lands on home; Restore → correct message;
      airplane mode → cached entitlement keeps the app usable.
- [ ] Copy contains no forbidden words (screen time / block / limit / control).
