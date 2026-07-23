# Nupo — Onboarding & Paywall Specification

> **Goal:** A high-converting onboarding that does two jobs at once:
> 1. Make the **parent feel deeply understood** (guilt, nagging fatigue, "nothing has stuck").
> 2. Make the parent **believe their child will actually enjoy it** — their #1 fear is "my kid will hate this."
>
> **Reference:** Teardown of Prayer Lock's 40-screen flow, plus established patterns from Noom (survey → personalized plan → paywall), Cal AI (projected-outcome graph), and Duolingo (mascot + streak).
>
> **Read §9 (Honest Guardrails) before building anything.** Some of what Prayer Lock does would be actively dangerous for a kids app under Google's Families policy.

---

## 1. The mechanics we're borrowing (and why they work)

| Mechanic | Why it works | Nupo's version |
|---|---|---|
| **Name capture early** | Every later screen feels bespoke | Capture **parent's name AND child's name**. The child's name is the emotional engine — every screen says "Aarav," not "your child." |
| **Shock stat from their own input** | Self-generated numbers are believed | "By 15, Aarav will have spent 10,000+ hours on a screen." |
| **Reframe the same number** | Turns despair into opportunity | "Nupo borrows 90 seconds of each hour — and gives back a habit." |
| **Reflection screens** | Plays their answer back = "they get me" | After goals + "what have you tried," mirror it back. |
| **Deliver value BEFORE paywall** | Walking away now costs something | Parent **experiences the real gate card** and answers a question themselves. |
| **Mascot with a stake** | Emotional ownership | Owl the child **names** and **grows**. Directly answers "will my kid quit?" |
| **Commitment ladder** | Consistency principle | "How committed are you?" → validation. |
| **Permissions as benefits** | Reduces drop-off at the scariest step | "This is how Aarav sees his learning moment." |
| **Paywall last** | Maximum sunk investment | After ~30 screens, a real gate demo, and a named owl. |

---

## 2. Design principles

1. **Every screen is ONE tap.** Length is fine (Prayer Lock runs ~40); friction is not. Momentum > brevity.
2. **The child's name appears everywhere** after capture. This is the single highest-leverage personalization.
3. **Tone = relief, not shame.** Parents are already drowning in screen-time guilt. Never make them feel like a bad parent (see §9).
4. **Two ahas: one fast, one deep.** A 20-second micro-aha in the hook, and the full personalized aha at Phase 7.
5. **Sell the outcome, never the mechanic.** They're not buying "an app blocker with quizzes." They're buying *a child who learns daily without a fight.*
6. **Pre-fill everything you can.** If they said the kid uses YouTube, pre-select YouTube in the app picker later.

---

## 3. THE FLOW — screen by screen

### PHASE 0 — The hook (4 screens, no input, ~20 sec)

Swipeable cards with the owl. Dot indicators. Big type, one line each.

**S1** — owl looking at a glowing phone
> ### Every day, your child reaches for the phone.
> And "we'll do some learning later" turns into… later.

**S2** — owl brightening
> ### Nupo turns that reach into a learning habit.

**S3** — locked app icons (YouTube, Roblox, a game — greyed with small locks)
> ### It's simple. Before games and videos open…

**S4 — ⭐ THE MICRO-AHA (this is the differentiator).** Don't just *tell* them — let them tap.
> ### …they answer a few quick questions.
>
> **Try it. What's 6 × 7?**
> [ 42 ] [ 48 ] [ 36 ]

→ On correct tap: owl does a celebration animation.
> ### 🎉 That's it. That's Nupo.
> 90 seconds of learning. Then they play.
> **[ Let's set it up for your child → ]**

**Why:** The user has now *experienced the core product 20 seconds after install*, before giving a single piece of data. Nobody in this category does this.

---

### PHASE 1 — Names (the personalization engine)

**S5**
> ### First — what should we call you?
> [ text input ] → *Priya*

**S6**
> ### And what's your child's name?
> Nupo will use it to make everything personal.
> [ text input ] → *Aarav*

> ⚙️ **Store both locally.** The child's name never leaves the device (see §8).

---

### PHASE 2 — The honest diagnostic

**S7**
> ### Priya, answer these honestly.
> It's how we get Nupo right for Aarav.
> **[ Let's start → ]**

**S8 — (functional: sets age band)**
> ### How old is Aarav?
> [ 5–7 · Counting & simple sums ]
> [ 8–10 · Mental math & general knowledge ]
> [ 11–13 · Logic puzzles & tricky questions ]

**S9 — (feeds the shock stat)**
> ### How long is Aarav on a screen each day?
> *be honest — no judgement here*
> [ Under 1 hour ] [ 1–2 hours ] [ 2–3 hours ] [ 3–4 hours ] [ 4+ hours ]

---

### PHASE 3 — ⚡ THE SHOCK → REFRAME → HOPE (the hinge of the funnel)

**S10 — The shock.** Computed from S8 + S9. Big number, emoji, muted background.
> 🤯
> ### Priya, at this rate Aarav will spend over
> # 10,000 hours
> ### on a screen before he turns 15.

*Math (do it honestly, from their inputs):*
`hours_per_day × 365 × (15 − child_age)`
→ 3 hrs/day, age 8 → 3 × 365 × 7 = **7,665 hours**. Round *down*, never inflate. If the number lands under 5,000, phrase it as "over X thousand hours" — don't manufacture drama.

**S11 — The reframe.** Same number, flipped.
> 📚
> ### That's the number people say it takes to **master a skill.**
> Right now, those hours are going nowhere.

**S12 — The hope.** (Note: we do NOT promise to reduce the hours — that's the pitch that failed in your survey.)
> 🦉
> ### Nupo doesn't take those hours away.
> ### It borrows **90 seconds** of each one.
> And gives Aarav a learning habit in return.
> **[ Continue ]**

---

### PHASE 4 — Goals + the mirror

**S13 — Multi-select (up to 3). Progress bar starts here.**
> ### What do you want for Aarav?
> *choose up to 3*
> - 📚 Build a daily learning habit
> - ➗ Get stronger at math
> - 🌍 Learn more about the world
> - 😤 Fewer fights about the phone
> - 🧠 Make screen time actually count
> - ⏰ Do it **without me nagging**
> - 🎯 Better focus and patience

**S14 — The mirror** (bold brand-colour background, like Prayer Lock's orange reflection screen). Take their **top pick** and play it back.
> **⏰ Do it without me nagging**
> *You shouldn't have to be the bad guy every evening. Nupo does the asking, so you don't have to.*
>
> **where Aarav is headed**
> ### 🎯 A daily learning habit — on autopilot
>
> ### You're not alone.
> "Fewer fights about the phone" is the single most common thing parents tell us.
> **[ Continue ]**

---

### PHASE 5 — The empathy questions (this is where they feel *seen*)

**S15**
> ### How does learning time usually go right now?
> - 😤 It's a daily negotiation
> - 😔 Honestly, I've mostly given up
> - 📖 He'll do it — but only if I sit with him
> - ✅ It's fine, I just want more

**S16 — ⭐ THE KEY QUESTION**
> ### What have you already tried?
> *choose any that apply*
> - 📓 Workbooks
> - 📱 Learning apps (he stopped opening them)
> - 🏫 Tuition or coaching
> - ⏱️ Screen time limits
> - 🚫 Taking the phone away
> - 😮‍💨 Honestly — nothing has stuck

**S17 — ⭐ THE "WE UNDERSTAND YOU" SCREEN.** This is the emotional peak of the whole flow.
> ### That's exactly why we built Nupo.
>
> Every one of those things asks Aarav to **stop** doing what he wants.
>
> So he resists. Every time.
>
> **Nupo doesn't ask him to stop.**
> It just adds 90 seconds first — then hands him the thing he already wanted.
>
> That's the whole trick. And it's why it works.
> **[ Continue ]**

**S18 — (functional: pre-fills the app picker later)**
> ### What does Aarav reach for most?
> *choose any*
> [ YouTube ] [ Roblox ] [ TikTok ] [ Instagram ] [ Games ] [ YouTube Kids ] [ Snapchat ]

---

### PHASE 6 — Building animation

**S19** — progress ring/bar, ~4 seconds, steps ticking over. (Real work: seeding the question bank for their band.)
> ### Building Aarav's learning plan…
> ✓ Matching questions to age 8
> ✓ Mixing math, logic & general knowledge
> ✓ Calibrating difficulty
> ⏳ Preparing his first lesson…
>
> *(35% … 70% … 100%)*

---

### PHASE 7 — ⭐⭐ THE BIG AHA: let the parent *be* the child

The single most important screen in the funnel. This is Prayer Lock's "complete your first prayer" moment — adapted.

**S20**
> ### Priya, this is exactly what Aarav will see.
> *Go ahead — try it yourself.*
> **[ Show me → ]**

**S21 — THE REAL GATE CARD.** Render the actual overlay UI, unmodified. Owl, stars, question card, age-appropriate question pulled from *their child's* band.
> 🦉 **Here's your learning moment!**
> ⭐ ☆ ☆
> *Question 1 of 3*
> ### 12 × 4 = ?
> [ numeric keypad ]

Let them answer all 3. Owl celebrates. Stars fill.

**S22 — The payoff**
> 🎉
> ### That's it. That's the whole thing.
> Aarav answers 3 quick questions → his app opens for 15 minutes.
>
> No lectures. No study sessions. No arguments.
> **[ Continue ]**

**Why this converts:** They have now *felt* the product. Every subsequent screen is asking them to keep something they've already used, not to buy something abstract.

---

### PHASE 8 — ⭐ MEET THE OWL (the "will my kid quit?" killer)

This is Nupo's answer to "meet Manna." It exists to solve the parent's deepest objection.

**S23** — owl card with a level badge and an XP/level bar, like a collectible.
> ### Meet Nupo — Aarav's learning buddy.
>
> [ owl illustration · **Level 1** · 🔥 0 day streak · XP bar at 5% ]
>
> Nupo levels up every time Aarav learns something.
> **Kids don't fight Nupo. They look after him.**

**S24 — Give the child ownership**
> ### What should Aarav call him?
> [ text input, pre-filled: "Nupo" ]
> *He can change it any time.*
> **[ Let's go → ]**

---

### PHASE 9 — The projection (Cal AI-style future pacing)

**S25** — a filling 30-square grid or rising line chart.
> ### Here's Aarav, 30 days from now.
>
> - **540** questions answered
> - **🔥 30** day learning streak
> - Times tables: *shaky → solid*
>
> …all inside time he was already spending.
> **[ I want that ]**

---

### PHASE 10 — Commitment ladder

**S26**
> ### So — how committed are you to making this happen for Aarav?
> - 🔥 Extremely committed
> - 💪 Very committed
> - 🤔 Somewhat committed
> - 🌱 A little committed
> - ✨ Just exploring

**S27 — Validation** (bold brand background)
> 👍
> ### We love to see this.
> Kids follow their parent's lead. Aarav's got a good one.
> **[ Done ✓ ]**

> ⚠️ Prayer Lock uses a literal **signature box** here. Skip it — see §9. A tap-to-commit is enough for parents; a signature reads as manipulative in a family context.

---

### PHASE 11 — Setup (functional — but pre-filled and framed as progress)

**S28 — App picker.** *Pre-select whatever they chose at S18.*
> ### Where should learning pop up?
> *(pre-toggled: YouTube, Roblox)*
> 📞 Phone, messages & clock always stay open.

**S29 — App rules**
> ### How much learning?
> Questions per lesson: **3** [− +]
> Minutes earned: **15m** [− +]
> Daily limit: [ toggle ]

**S30 — Parent PIN**
> ### Create your PIN
> Just for grown-ups — opens settings and skips a lesson.

**S31–33 — Permissions, framed as benefits (one screen each, with live ✓/✗ status)**
> ### One last thing — Nupo needs 3 permissions.
>
> **1. Appear over other apps**
> *This is how Aarav sees his learning moment.*
> **[ Allow ]**
>
> **2. Accessibility service**
> *This lets Nupo know when Aarav opens YouTube.*
> **[ Turn on ]**
>
> **3. Battery optimization off**
> *So Nupo keeps working, even in the background.*
> **[ Allow ]**

> ⚙️ Deep-link each button straight to the system screen. Re-check state on app resume. This is the #1 drop-off point in the entire app — do not bury it in text.

---

### PHASE 12 — Attribution (cheap, useful)

**S34**
> ### Where did you hear about us?
> [ YouTube ] [ Instagram ] [ TikTok ] [ Friends or family ] [ Play Store search ] [ Other ]

---

### PHASE 13 — Social proof → Paywall

**S35 — Social proof.** ⚠️ **Read §9 first — do not fabricate numbers.**

*At launch (no users yet), use the science instead of fake stats:*
> ### Why this works
> Nupo is built on one of the most reliable ideas in child psychology: put the thing they **should** do right before the thing they **want** to do.
>
> It's the same reason "veggies before dessert" works — and it's why Aarav won't fight it the way he fights a workbook.

*Once you have real reviews and real numbers, swap this screen for genuine testimonials.*

**S36 — ⭐ THE PAYWALL**

> 🦉
> ### It's not about more discipline.
> ### It's about a better habit.
>
> Aarav doesn't need to be forced to learn. He just needs a reason to start — every single day.
>
> **Here's what Aarav's first 7 days look like:**
>
> 🔑 **Day 1 — the first unlock**
> He answers 3 questions, earns his game. No fight.
>
> 🛡️ **Day 2 — the resistance**
> He'll test it. He'll try to get around it. Nupo holds.
>
> 🔁 **Day 3 — the habit forms**
> He stops asking why. It's just what happens before Roblox now.
>
> 🎉 **Day 7 — 100+ questions answered**
> And you haven't nagged once.
>
> ---
> ✓ **No payment due now**
> **[ Start free trial ]**
> *then ₹X/year (₹Y/week)*

**S37 — Trial reminder**
> 🔔
> ### We'll remind you before your free trial ends.
> ✓ No payment due now
> **[ Continue for free ]**

**S38 — Google Play purchase sheet** (system UI)

---

## 4. Pricing recommendation

Your parent survey said **one-time payment**, but subscriptions are what make indie apps viable. Don't pick — **offer both** on the paywall:

- **Annual** (default, highlighted, "best value") — with a 3–7 day free trial.
- **Lifetime / one-time** — for the large segment of parents who refuse subscriptions.

Parents who'd have bounced at a subscription convert on lifetime; everyone else subscribes. Test the ratio later.

---

## 5. The fast-aha summary (you asked for this specifically)

You get **three** ahas, escalating:

| When | What | Cost to user |
|---|---|---|
| **~20 seconds** (S4) | Tap an answer, owl celebrates. "That's Nupo." | Zero |
| **~2 minutes** (S17) | "That's exactly why we built Nupo" — they feel *seen* | Zero |
| **~4 minutes** (S21) | They play the *real* gate with their child's actual questions | Zero |

By the paywall they have used the product three times and paid nothing. That's the whole game.

---

## 6. What makes THIS onboarding different from every competitor

1. **Micro-aha in the first 20 seconds** — nobody does this.
2. **The child's name everywhere** — turns a tool into a relationship.
3. **The "what have you tried" → "that's exactly why" turn** — this is your emotional kill shot. It reframes every failed workbook and abandoned app as *proof that Nupo is different*.
4. **Letting the parent BE the child** (S21) — pre-emptively kills "will he actually do it?"
5. **The nameable, level-up owl** (S23–24) — pre-emptively kills "he'll just delete it."

---

## 7. Data & personalization (technical)

| Field | Captured | Stored | Transmitted? |
|---|---|---|---|
| Parent name | S5 | Local | No |
| **Child name** | S6 | **Local only** | **Never** |
| Child age band | S8 | Local | Coarse band only (existing behaviour) |
| Screen-time estimate | S9 | Local (used for shock stat) | No |
| Goals / tried-before / pain | S13–S16 | Local | *Aggregate only, if at all — see §9* |
| Apps chosen | S18 | Local | Count only |
| Attribution | S34 | Can transmit (parent-flow, anonymous) | Yes, aggregate |

**Rule:** the survey personalizes **on-device**. It is not a data-collection exercise. This keeps your Data Safety declaration and privacy policy honest and unchanged.

---

## 8. Build order

1. **S20–S22 (the gate demo)** — build this first. It reuses your existing overlay card. Highest impact, lowest new work.
2. **S5–S6 (names)** + threading the child's name through every string.
3. **S8–S12 (diagnostic + shock/reframe/hope)** — the arc that hooks.
4. **S13–S17 (goals + mirror + empathy)** — the "we get you" block.
5. **S23–S25 (owl + projection)**.
6. **S28–S33 (setup + permissions)** — mostly exists already; just re-order and re-copy.
7. **S35–S37 (paywall)** — wire to RevenueCat.
8. **S1–S4 (hook + micro-aha)** — small, do it last, but don't skip it.

---

## 9. ⚠️ HONEST GUARDRAILS — read before copying Prayer Lock

Prayer Lock does several things you **must not** copy. Some are legal risks; some will backfire specifically because you're a kids app.

**1. DO NOT fabricate statistics.**
Prayer Lock shows *"92.08% of prayer lock users formed a daily prayer habit"* and *"500,000+ Christians."* If you don't have that data, claiming it is **deceptive advertising** — it violates Google Play policy, consumer protection law, and it's exactly the kind of thing that gets a Families-program app pulled. You have ~2 real users. Use the **science** (Premack principle) or **real testimonials from your actual testers** until you have genuine numbers. Then swap them in.

**2. DO NOT weaponize parental guilt.**
Their flow works because an adult is judging *themselves*. Parents are already saturated with screen-time shame. Push the guilt lever hard and you get one-star reviews saying *"made me feel like a terrible parent."* Your tone must be **relief**: *"This isn't your fault. Screens aren't going away. Here's what actually works."* Notice S10–S12 states the number, then immediately absolves and redirects. Keep it that way.

**3. Skip the signature contract.**
Fine for a personal-faith app. In a parenting context it reads as manipulative. A commitment *tap* (S26) gets you 90% of the consistency effect with none of the ick.

**4. Be honest about the shock number.**
Compute it from their real inputs and **round down**. Don't inflate to make it scarier. If a parent does the math and it doesn't hold up, you've lost them permanently — and they're the type who'll say so in a review.

**5. Don't promise reduced screen time.**
Your own survey proved this backfires. S12 is deliberately worded *"Nupo doesn't take those hours away."* Keep it.

**6. Google Play subscription rules.**
Trial terms, price, and renewal must be clear **before** purchase (Prayer Lock does this correctly: "No Payment Due Now" + visible annual price + the Play sheet). Don't obscure it.

**7. Families policy — parental gate.**
Your paywall must not be reachable by a child. Since onboarding is parent-driven and PIN-protected, you're mostly fine — but **confirm** a child hitting the app fresh cannot reach a purchase flow.

**8. Length is fine. Friction is not.**
~38 screens sounds long, but each is one tap and momentum builds. What kills conversion is *typing*, *thinking*, or *confusion* — not screen count.

---

## 10. Copy bank (every string, ready to drop in)

*(All strings use `{parent}` and `{child}` placeholders.)*

- Hook 1: `Every day, {child} reaches for the phone.`
- Hook 2: `Nupo turns that reach into a learning habit.`
- Hook 4 payoff: `🎉 That's it. That's Nupo. 90 seconds of learning. Then they play.`
- Name: `And what's your child's name?` / `Nupo will use it to make everything personal.`
- Diagnostic intro: `{parent}, answer these honestly. It's how we get Nupo right for {child}.`
- Screen time Q: `How long is {child} on a screen each day?` / `be honest — no judgement here`
- **Shock:** `At this rate, {child} will spend over {N} hours on a screen before he turns 15.`
- **Reframe:** `That's the number people say it takes to master a skill. Right now, those hours are going nowhere.`
- **Hope:** `Nupo doesn't take those hours away. It borrows 90 seconds of each one.`
- **The kill shot (S17):** `That's exactly why we built Nupo. Every one of those things asks {child} to stop doing what he wants. So he resists. Every time. Nupo doesn't ask him to stop — it just adds 90 seconds first, then hands him the thing he already wanted.`
- Demo intro: `{parent}, this is exactly what {child} will see. Go ahead — try it yourself.`
- Demo payoff: `That's it. That's the whole thing. No lectures. No study sessions. No arguments.`
- Owl: `Meet Nupo — {child}'s learning buddy.` / `Kids don't fight Nupo. They look after him.`
- Projection: `Here's {child}, 30 days from now.`
- Commitment validation: `We love to see this. Kids follow their parent's lead. {child}'s got a good one.`
- Paywall headline: `It's not about more discipline. It's about a better habit.`
- Paywall sub: `{child} doesn't need to be forced to learn. He just needs a reason to start — every single day.`
- Paywall day 7: `100+ questions answered. And you haven't nagged once.`

---

## 11. Notes for Claude Code

- Thread `{child}` through **every** string after S6. This is the highest-leverage thing in the whole spec.
- **S21 must render the real overlay card**, not a mockup — import the actual gate widget so the demo and the product can never drift apart.
- The shock stat (S10) must be **computed live** from S8 + S9. Round down.
- Pre-select S18's apps in the S28 picker. Pre-filling is what makes it feel intelligent.
- Survey answers stay **on-device**. Do not add analytics SDKs to capture them (see §7 and the existing Data Safety declaration).
- Permissions (S31–33) are the biggest drop-off risk: deep-link each one, show live ✓/✗, re-check on resume.
- Keep every screen to one tap. No typing except the two names and the owl's name.
