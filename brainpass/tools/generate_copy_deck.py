from __future__ import annotations

import html
import re
from pathlib import Path

from reportlab.lib import colors
from reportlab.lib.enums import TA_CENTER
from reportlab.lib.pagesizes import A4, landscape
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.lib.units import mm
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.platypus import (
    BaseDocTemplate,
    Frame,
    KeepTogether,
    ListFlowable,
    ListItem,
    PageBreak,
    PageTemplate,
    Paragraph,
    Spacer,
    Table,
    TableStyle,
)

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "docs" / "Nupo_Complete_App_Copy_Deck.pdf"
OUT.parent.mkdir(parents=True, exist_ok=True)

pdfmetrics.registerFont(TTFont("Nunito", ROOT / "assets/fonts/Nunito-Regular.ttf"))
pdfmetrics.registerFont(TTFont("NunitoBold", ROOT / "assets/fonts/Nunito-Bold.ttf"))
pdfmetrics.registerFont(TTFont("NunitoBlack", ROOT / "assets/fonts/Nunito-Black.ttf"))

PURPLE = colors.HexColor("#7C3AED")
INK = colors.HexColor("#241C3B")
MUTED = colors.HexColor("#6F687E")
LILAC = colors.HexColor("#F6F1FF")
YELLOW = colors.HexColor("#F9C13C")
GREEN = colors.HexColor("#0E9384")
LINE = colors.HexColor("#E7DDF7")

styles = getSampleStyleSheet()
styles.add(ParagraphStyle(name="DeckTitle", fontName="NunitoBlack", fontSize=13, leading=14, textColor=INK, spaceAfter=3))
styles.add(ParagraphStyle(name="DeckSub", fontName="Nunito", fontSize=6, leading=7.5, textColor=MUTED, spaceAfter=4))
styles.add(ParagraphStyle(name="ScreenNo", fontName="NunitoBold", fontSize=5.6, leading=6.5, textColor=PURPLE, tracking=.5, spaceBefore=4, spaceAfter=1))
styles.add(ParagraphStyle(name="ScreenTitle", fontName="NunitoBlack", fontSize=9, leading=10, textColor=INK, spaceAfter=1))
styles.add(ParagraphStyle(name="Route", fontName="NunitoBold", fontSize=5.2, leading=6.4, textColor=GREEN, spaceAfter=3))
styles.add(ParagraphStyle(name="Section", fontName="NunitoBlack", fontSize=7.5, leading=9, textColor=INK, spaceBefore=4, spaceAfter=2))
styles.add(ParagraphStyle(name="Body", fontName="Nunito", fontSize=5.5, leading=7, textColor=INK, spaceAfter=2))
styles.add(ParagraphStyle(name="Copy", fontName="NunitoBold", fontSize=5.9, leading=7.1, textColor=INK, leftIndent=3, rightIndent=2, spaceAfter=.4))
styles.add(ParagraphStyle(name="Meta", fontName="Nunito", fontSize=4.8, leading=5.9, textColor=MUTED, leftIndent=3, rightIndent=2, spaceAfter=1.5))
styles.add(ParagraphStyle(name="Small", fontName="Nunito", fontSize=4.8, leading=5.8, textColor=MUTED))
styles.add(ParagraphStyle(name="Appendix", fontName="NunitoBlack", fontSize=10, leading=11, textColor=INK, spaceAfter=3))


def esc(value: object) -> str:
    return html.escape(str(value)).replace("\n", "<br/>")


def footer(canvas, doc):
    canvas.saveState()
    canvas.setStrokeColor(LINE)
    canvas.line(10 * mm, 8 * mm, 287 * mm, 8 * mm)
    canvas.setFont("Nunito", 5.5)
    canvas.setFillColor(MUTED)
    canvas.drawString(10 * mm, 4.5 * mm, "NUPO COMPLETE APP COPY DECK")
    canvas.drawRightString(287 * mm, 4.5 * mm, f"{doc.page}")
    canvas.restoreState()


PAGE = landscape(A4)
doc = BaseDocTemplate(
    str(OUT), pagesize=PAGE, rightMargin=10 * mm, leftMargin=10 * mm,
    topMargin=9 * mm, bottomMargin=11 * mm,
    title="Nupo Complete App Copy Deck",
    author="Nupo product documentation",
)
GAP = 5 * mm
COL_WIDTH = (doc.width - 2 * GAP) / 3
frames = [Frame(doc.leftMargin + i * (COL_WIDTH + GAP), doc.bottomMargin,
                COL_WIDTH, doc.height, id=f"col{i}", leftPadding=0,
                rightPadding=0, topPadding=0, bottomPadding=0) for i in range(3)]
doc.addPageTemplates([PageTemplate(id="copy", frames=frames, onPage=footer)])
story = []


def copy_row(place: str, text: str, state: str | None = None):
    body = [
        Paragraph(esc(place).upper(), styles["Small"]),
        Paragraph(f'“{esc(text)}”', styles["Copy"]),
    ]
    if state:
        body.append(Paragraph(esc(state), styles["Meta"]))
    else:
        body.append(Spacer(1, 1))
    return KeepTogether(body)


def screen(number: str, title: str, route: str, entries, notes: str | None = None):
    story.extend([
        Paragraph(f"SCREEN {esc(number)}", styles["ScreenNo"]),
        Paragraph(esc(title), styles["ScreenTitle"]),
        Paragraph(esc(route), styles["Route"]),
    ])
    if notes:
        story.append(Table([[Paragraph(esc(notes), styles["Body"])]], colWidths=[COL_WIDTH], style=[
            ("BACKGROUND", (0, 0), (-1, -1), LILAC),
            ("BOX", (0, 0), (-1, -1), 0.8, LINE),
            ("LEFTPADDING", (0, 0), (-1, -1), 4),
            ("RIGHTPADDING", (0, 0), (-1, -1), 4),
            ("TOPPADDING", (0, 0), (-1, -1), 3),
            ("BOTTOMPADDING", (0, 0), (-1, -1), 2),
        ]))
        story.append(Spacer(1, 2))
    for place, text, *state in entries:
        story.append(copy_row(place, text, state[0] if state else None))
    story.append(Spacer(1, 3))


# Cover
story.extend([
    Paragraph("NUPO", styles["ScreenNo"]),
    Paragraph("Complete App Copy Deck", styles["DeckTitle"]),
    Paragraph("Every visible word, in journey order, with placement, state and dynamic content notes", styles["DeckSub"]),
    Spacer(1, 2 * mm),
    Table([
        [Paragraph("SCOPE", styles["Small"]), Paragraph("Android parent app, onboarding story, setup, dashboard, account states and native child learning gate", styles["Body"])],
        [Paragraph("DYNAMIC TOKEN", styles["Small"]), Paragraph("[Child name], [Owl name], [App name], [Phone number], [Question], [Answer], [Countdown]", styles["Body"])],
        [Paragraph("READING ORDER", styles["Small"]), Paragraph("Top to bottom within each screen. Conditional states follow the default state.", styles["Body"])],
    ], colWidths=[23 * mm, COL_WIDTH - 23 * mm], style=[
        ("BACKGROUND", (0, 0), (-1, -1), LILAC), ("GRID", (0, 0), (-1, -1), .7, LINE),
        ("VALIGN", (0, 0), (-1, -1), "TOP"), ("LEFTPADDING", (0, 0), (-1, -1), 9),
        ("RIGHTPADDING", (0, 0), (-1, -1), 3), ("TOPPADDING", (0, 0), (-1, -1), 3),
    ]),
    Spacer(1, 4),
])

screen("00", "Brand splash", "Launch → Splash", [
    ("Center", "Nupo logo artwork", "No written copy on this screen."),
], "The splash is intentionally copy free. The logo is the only communicative element.")

screen("01", "Welcome", "New install → Onboarding story", [
    ("Mascot artwork", "Hi!"),
    ("Audience pill", "FOR PARENTS · AGES 5 TO 12"),
    ("Headline", "Learning they'll actually do"),
    ("Supporting copy", "A little learning before the apps they love. Set it up in two minutes."),
    ("Primary button", "Get started"),
    ("Secondary action", "I already have an account · Log in"),
])

screen("02", "Recognition", "Onboarding story · Beat 1", [
    ("Audience label", "FOR PARENTS · AGES 5 TO 12"),
    ("Headline", "They grab the phone the second they're bored."),
    ("Supporting copy", "You already know how this goes."),
    ("Bottom scroll hint", "KEEP SCROLLING"),
])

screen("03", "The possibility", "Onboarding story · Beat 2", [
    ("Headline", "What if they earned it with 30 seconds of learning?"),
    ("Background learning marks", "7×8 · A B C · ½ · ? · ★", "Decorative, low emphasis."),
])

screen("04", "Meet Nupo", "Onboarding story · Beat 3", [
    ("Headline", "That's Nupo."),
    ("Supporting copy", "A tiny lesson, right before the app opens."),
])

screen("05", "Story app choice", "Onboarding story · Beat 4", [
    ("Eyebrow", "NUPO ASKS"),
    ("Headline", "Which app do they open the most?"),
    ("Mascot bubble", "Pick the one they reach for first"),
    ("Option", "YouTube"), ("Option", "Roblox"), ("Option", "TikTok"),
    ("Selected headline", "Great. That's all Nupo needed."),
    ("Selected bubble", "Nupo will guard this one"),
    ("Confirmation pill", "Nupo remembers [App name]"),
])

screen("06", "Learning gate demonstration", "Onboarding story · Phone scene", [
    ("Shield headline", "Time to learn"),
    ("Shield body", "Answer a few quick questions to earn time on [App name]."),
    ("Primary button", "Earn time"),
    ("Caption", "This is the screen they meet, drawn by Nupo."),
    ("Quiz intro", "Quick one first!"),
    ("Question", "7 × 8 = ?", "Demonstration question."),
    ("Answer options", "54 · 56 · 48"),
    ("Instruction", "Tap the answer. This is what they see."),
    ("Wrong feedback variants", "Not quite! · That one's wrong. Try again. · Still not it. · Take your time. Try again."),
    ("Success feedback", "Nailed it!"),
    ("Payoff", "Nice! [App name] is open for 15 mins."),
])

screen("07", "Story close", "Onboarding story · Final beat", [
    ("Headline", "That's it."),
    ("Body", "Nothing to police. No arguing. They learn a little, then they're off. Every single time."),
    ("Benefit chip", "2 minute setup"), ("Benefit chip", "No ads"), ("Benefit chip", "You set the rules"),
    ("Primary button", "I want this for them"),
])

screen("08", "Phone sign in", "Returning parent or completed story → Login", [
    ("Headline", "Hi! Sign in to start"),
    ("Body", "Type your mobile number. We'll send a 6 digit code by SMS."),
    ("Field placeholder", "Phone number"),
    ("Information pill", "Use a parent's number. The code arrives there."),
    ("Primary button", "Send code"),
], "Country flag and dialling code are dynamic. Country picker rows show country name and dialling code.")

screen("09", "SMS verification", "Login → OTP", [
    ("Headline", "Type the 6 digit code"),
    ("Body", "We sent it by SMS to [Phone number]"),
    ("Utility action", "Paste code"),
    ("Countdown action", "Resend code in [Countdown]s"),
    ("Enabled action", "Resend code"),
])

screen("10", "Child name", "Personal setup · Step 1 of 5", [
    ("Progress label", "1/5"), ("Eyebrow", "STEP 1 OF 5"),
    ("Headline", "First, what's their name?"), ("Field placeholder", "Their name"),
    ("Empty helper", "Type a name and I'll remember it."),
    ("Typed helper", "Nice to meet you, [Child name]!"),
    ("Primary button", "Continue"),
])

screen("11", "Child age", "Personal setup · Step 2 of 5", [
    ("Progress label", "2/5"), ("Headline", "How old is [Child name]?"),
    ("Option", "5 and 6 years old · Counting, first words"),
    ("Option", "7 and 8 years old · Mental maths, nature and the world"),
    ("Option", "9 and 10 years old · Times tables, fractions"),
    ("Option", "11 and 12 years old · Word problems, logic"),
    ("Mascot response", "Little ones get pictures and counting. / Mental maths and the world around them. / Tables and fractions land best here. / I'll push into word problems and logic."),
    ("Primary button", "Continue"),
])

screen("12", "Learning goal", "Personal setup · Step 3 of 5", [
    ("Progress label", "3/5"), ("Headline", "What should [Child name] get better at?"),
    ("Goal card", "Maths · Confidence with numbers"),
    ("Goal card", "Reading · Stronger words and stories"),
    ("Goal card", "General knowledge · A wider view of the world"),
    ("Goal card", "A bit of everything · A balanced daily mix"),
    ("Mascot response", "Numbers first. I'll sneak the rest in. / Words and stories it is. / Capitals, planets, odd facts. / A bit of each, every day."),
    ("Primary button", "Continue"),
])

screen("13", "Name the owl", "Personal setup · Step 4 of 5", [
    ("Progress label", "4/5"),
    ("Headline", "Meet [Child name]'s buddy. What should they call him?"),
    ("Field placeholder", "Nupo"),
    ("Empty helper", "Nupo works too. That's me."),
    ("Typed helper", "[Owl name] it is. I like it."),
    ("Primary button", "Let's go"),
])

month_variants = (
    "Maths, younger: Counting to 100 · Adding to 10; Taking away · Shapes around us; Counting money · Telling the time; Doubles and halves · Simple word problems.\n"
    "Maths, older: Times tables to 10 · Counting money; Fractions · Place value; Multiplication to 12 · Simple logic; Word problems · Division basics.\n"
    "Reading, younger: Letter sounds · Rhyming words; Sight words · Simple sentences; Story order · Opposites; Reading for meaning · New words.\n"
    "Reading, older: Vocabulary builders · Synonyms; Reading comprehension · Prefixes; Idioms · Story structure; Inference · Spelling patterns.\n"
    "General knowledge, younger: Animals of the world · Colours and flags; My body · Seasons and weather; Fruits and plants · Community helpers; Land and water · Famous places.\n"
    "General knowledge, older: World capitals · Rivers and mountains; The solar system · Inventions; Human body · Ancient history; Flags and currencies · Famous firsts.\n"
    "Mixed, younger: Counting and sums · Letter sounds; Shapes · Animals of the world; Telling the time · Sight words; Simple logic · Seasons and weather.\n"
    "Mixed, older: Times tables to 10 · Counting money; Fractions · World capitals; Multiplication to 12 · Simple logic; Word problems · The solar system."
)
screen("14", "First month plan", "Personal setup · Step 5 of 5", [
    ("Progress label", "5/5"), ("Mascot bubble", "Four weeks. I have it planned already."),
    ("Eyebrow", "THE PLAN"), ("Headline", "[Child name]'s first month"),
    ("Supporting line", "A small win every week"),
    ("Week 1 label", "Build the base"), ("Week 2 label", "Add a challenge"),
    ("Week 3 label", "Make it stick"), ("Week 4 label", "Use it with confidence"),
    ("Dynamic weekly topics", month_variants),
    ("Primary button", "Continue"),
])

screen("15", "Thirty day projection", "Plan payoff", [
    ("Progress label", "Plan"), ("Animated number", "~500"),
    ("Metric label", "questions answered"),
    ("Body", "In 30 days, and you won't have nagged once."),
    ("Primary button", "Start [Child name]'s plan"),
], "The ~500 figure is an arithmetic projection based on approximately four gates per day, four questions per gate and thirty days.")

screen("16", "Why it works", "Plan explanation", [
    ("Progress label", "Plan"), ("Eyebrow", "THE IDEA"),
    ("Headline", "Why this actually works"),
    ("Body", "Learning becomes the key to something they already want."),
    ("Diagram label", "THE NEW ROUTINE"),
    ("Diagram step 1", "Choose an app"), ("Diagram step 2", "Quick learning"), ("Diagram step 3", "Enjoy the app"),
    ("Explanation card", "It feels natural to [Child name] because the reward is immediate and the learning is brief."),
    ("Primary button", "Makes sense"),
])

screen("17", "Choose protected apps", "Android setup · App picker", [
    ("Headline", "Where should learning pop up?"),
    ("Body", "A short lesson appears before each of these opens for [Child name]."),
    ("Section label", "POPULAR"),
    ("Installed apps action", "More apps on this phone"),
    ("Expanded section label", "ON THIS PHONE"),
    ("Empty state", "No other apps found."),
    ("Disabled button", "Pick at least one app"), ("Enabled button", "Continue"),
    ("Safety note", "Phone, messages & clock always stay open"),
], "App names and category labels are populated from the device. Preset app labels include YouTube, Roblox and TikTok where available.")

screen("18", "App learning rules", "Android setup · Rules", [
    ("Headline", "How much learning?"),
    ("Body", "For each app: how many questions [Child name] answers, and how many minutes of play that earns."),
    ("Rule summary", "[Question count] question(s) → [Minutes] min"),
    ("Control", "Questions per lesson"), ("Control", "Minutes of play"),
    ("Control", "Daily limit"), ("Control", "Max per day"),
    ("Primary button", "Continue", "Shows Save when opened from Parent settings."),
    ("Information pill", "You can change these any time"),
    ("Empty state title", "No apps picked yet"),
    ("Empty state body", "Go back and pick at least one app first."),
    ("Empty state button", "Back"),
])

screen("19", "Create parent PIN", "Android setup · Security", [
    ("Headline", "Create your parent PIN"),
    ("Body", "4 digits only you know. It opens the parent settings."),
    ("Confirmation headline", "Type it once more"),
    ("Confirmation body", "Just to make sure. Use the same 4 digits."),
    ("Error", "PINs didn't match. Try again"),
])

screen("20", "Permissions introduction", "Android setup · Almost there", [
    ("Eyebrow", "ALMOST THERE"), ("Mascot bubble", "Four switches and I can get to work."),
    ("Headline", "One last thing. [3 or 4] quick switches."),
    ("Body", "Android needs your OK for Nupo to do its job. Each one takes a few seconds, and we'll bring you right back."),
    ("Capability", "Show lessons over chosen apps"),
    ("Capability", "Notice when a chosen app opens"),
    ("Capability", "Keep working in the background"),
    ("Optional capability", "Restart itself if the phone closes it"),
    ("Primary button", "Let's do it"),
])

screen("21A", "Permission: display over apps", "Android setup · Permission 1", [
    ("Headline", "Let lessons appear"),
    ("Body", "Turn on “Display over other apps”. This lets Nupo show a quick question before a game or video opens."),
    ("Primary button", "Turn it on"), ("Footnote", "You'll be brought right back here."),
    ("Success state", "All set"), ("Optional action", "Skip for now"),
])

screen("21B", "Permission: usage access", "Android setup · Permission 2", [
    ("Headline", "Let Nupo see app opens"),
    ("Body", "Find Nupo in the list and switch it on. This is how Nupo knows it's lesson time."),
    ("Instruction card", "In the screen that opens, turn this on:"),
    ("Setting name", "Nupo"), ("Primary button", "Turn it on"),
    ("Footnote", "You'll be brought right back here."), ("Success state", "All set"),
])

screen("21C", "Permission: battery", "Android setup · Permission 3", [
    ("Headline", "Keep Nupo awake"),
    ("Body", "Tap Allow on the popup, so your phone doesn't put Nupo to sleep."),
    ("Primary button", "Allow"), ("Optional action", "Skip for now"), ("Success state", "All set"),
])

screen("21D", "Permission: autostart", "Android setup · OEM conditional", [
    ("Headline", "Let Nupo restart itself"),
    ("Body", "Phones sometimes close apps to save power. Find Nupo in the list and switch Autostart on."),
    ("Instruction card", "In the screen that opens, turn this on:"),
    ("Setting name", "Nupo"), ("Primary button", "Open settings"), ("Success state", "All set"),
])

screen("22", "Subscription gate", "After setup · When paywall is enabled and Pro is inactive", [
    ("Store paywall", "Product title, price, benefits, purchase CTA and legal copy are supplied by RevenueCat's current paywall configuration."),
    ("Footer action", "Restore purchases"),
], "This screen's primary commercial copy is remote content. The app repository only owns the restore action shown below the RevenueCat paywall.")

screen("23", "Active landing", "Completed setup · Main screen", [
    ("Status pill", "Learning on"), ("Headline", "All set!"),
    ("Body", "When your child opens a chosen app, Nupo asks a few quick questions first. Then they play."),
    ("How it works", "Open app → Answer → Play"),
    ("Primary button", "Parent settings"),
    ("Footer pill", "A few minutes of learning, every day"),
    ("Paused status", "Paused"), ("Paused headline", "Nupo is paused"),
    ("Paused body", "Apps open freely right now. Turn Nupo back on in Parent settings."),
])

screen("24", "Parent PIN entry", "Main screen → Parent settings", [
    ("Top title", "Parent settings"), ("Headline", "Enter your parent PIN"),
    ("Body", "The 4 digits you chose during setup."),
    ("Error", "Wrong PIN. Try again"), ("Action", "Forgot PIN?"),
    ("Dialog title", "Forgot your PIN?"),
    ("Dialog body", "For safety, your PIN can't be recovered.\n\nTo reset: Android Settings → Apps → Nupo → Storage → Clear data, then set Nupo up again."),
    ("Dialog button", "OK"),
])

screen("25", "Parent settings dashboard", "PIN accepted → Parent settings", [
    ("Top title", "Parent settings"),
    ("Permission warning title", "A permission is off"),
    ("Permission warning body", "Nupo can't bring lessons right now. Tap to fix."),
    ("Master status", "Learning on · A quick lesson before play"),
    ("Paused status", "Paused · Apps open freely"),
    ("Section", "Learning apps"), ("Action", "Edit"), ("Empty state", "No apps picked yet."),
    ("App usage", "[Used minutes] min today · [Remaining minutes] min left / No daily limit"),
    ("Section", "Settings"), ("Row", "Child age · [Age band]"),
    ("Row", "Permissions · All granted / Needs attention"), ("Row", "Change PIN · ••••"),
    ("Section", "Account"), ("Row", "Signed in · [Phone number / Not available]"),
    ("Row", "Subscription · Nupo Pro / Inactive"), ("Row", "Sign out"), ("Row", "Delete account"),
])

screen("26", "Edit child age", "Parent settings → Child age", [
    ("Headline", "How old is your child?"),
    ("Body", "Questions will match their age. You can change this any time."),
    ("Age band", "Ages 5 and 6 · Counting & simple sums"),
    ("Age band", "Ages 7 and 8 · Mental math & nature"),
    ("Age band", "Ages 9 and 10 · Times tables & trivia"),
    ("Age band", "Ages 11+ · Advanced logic & math"),
    ("Action", "Enter exact age"), ("Preview label", "Sample questions"),
    ("Exact age sheet", "How old? · 5 · 6 · 7 · 8 · 9 · 10 · 11"),
    ("Primary button", "Continue"),
])

screen("27", "Permissions status", "Parent settings → Permissions", [
    ("Top title", "Permissions"),
    ("Body", "Green means working. Tap Open to fix anything that's off."),
    ("Row", "Display over other apps · Working / Needs attention"),
    ("Row", "Usage access · Working / Needs attention"),
    ("Row", "Background battery · Working / Recommended"),
    ("Conditional row", "Restart automatically · Open settings"),
    ("Row action", "Open"), ("Footer pill", "Nupo only watches the apps you picked"),
    ("Primary button", "Done"),
])

screen("28", "Account confirmation dialogs", "Parent settings → Account actions", [
    ("Sign out title", "Sign out?"),
    ("Sign out body", "You'll need to sign in again with your phone number to use Nupo."),
    ("Dialog actions", "Cancel · Sign out"),
    ("Delete title", "Delete account?"),
    ("Delete body", "This permanently deletes your Nupo account. This cannot be undone."),
    ("Dialog actions", "Cancel · Delete"),
    ("Delete error title", "Couldn't delete"), ("Delete error action", "OK"),
])

screen("29", "Delete account verification", "Delete account → Reauthentication", [
    ("Top title", "Delete account"), ("Headline", "Confirm it's you"),
    ("Body", "Enter the code sent to [Phone number] to permanently delete your account."),
    ("Countdown action", "Resend code in [Countdown]s"), ("Enabled action", "Resend code"),
])

screen("30", "Child learning gate", "Child opens a protected app · Native Android overlay", [
    ("Session progress", "[Solved count] of [Target count]"),
    ("Boss label", "BOSS STAR"),
    ("Question types", "Numeric keypad · Multiple choice · True or false · Odd one out · Count · Compare · Match pairs · Put in order · Word builder · Memory"),
    ("Static prompts", "Tap the odd one out! · Tap the BIGGER one! · Match the pairs! · Put them in order, smallest first! · Remember these! · Which one did you see?"),
    ("Correct feedback", "[Affirmation] · [Streak] in a row!"),
    ("Boss success", "BOSS CLEARED! [Affirmation]"),
    ("Wrong feedback", "Oops! It was [Correct answer] · Oops! Not [Answer], look again · Almost! Try a different order"),
    ("Daily completion headline", "You're a star today! 🌟"),
    ("Daily completion body", "Great learning today.\nSee you tomorrow! 👋"),
    ("Parent override title", "Parent PIN"), ("Override error", "Wrong PIN"), ("Override action", "← Back"),
], "Question wording and answer content are generated from the age appropriate native question engine. The full general knowledge bank follows in the appendix.")

screen("31", "Authentication and service errors", "Conditional global copy", [
    ("Invalid phone", "That number doesn't look right. Check and try again."),
    ("Missing phone", "Please enter your phone number."),
    ("Invalid code", "That code isn't right. Try again."),
    ("Expired code", "That code expired. Tap Resend for a new one."),
    ("Rate limit", "Too many tries. Please wait a bit and try again."),
    ("Network", "No internet. Connect to WiFi and try again."),
    ("Service quota", "Service is busy right now. Please try again later."),
    ("Recent login required", "For your security, please sign in again first."),
    ("Fallback", "Something went wrong. Please try again."),
])


# Appendix: question templates and full Dart GK bank.
story.extend([
    Paragraph("APPENDIX A", styles["ScreenNo"]),
    Paragraph("Generated question copy patterns", styles["Appendix"]),
    Paragraph("Variable letters represent generated numbers or symbols. The exact values change each session.", styles["Body"]),
])
templates = [
    "a + b = ?", "a − b = ?", "a × b = ?", "a ÷ b = ?", "n² = ?",
    "symbol + symbol = total · What is symbol?", "number sequence, ?",
    "Tap the odd one out!", "Tap the BIGGER one!", "Match the pairs!",
    "Put them in order, smallest first!", "Remember these!", "Which one did you see?",
]
story.append(ListFlowable([ListItem(Paragraph(esc(x), styles["Body"])) for x in templates], bulletType="bullet", leftIndent=15))
story.append(Spacer(1, 4))


def gk_cards_from_dart():
    src = (ROOT / "lib/questions.dart").read_text(encoding="utf-8")
    cards = []
    pos = 0
    while True:
        start = src.find("GkCard(", pos)
        if start < 0:
            break
        depth, i, quote, escaped = 0, start + len("GkCard"), None, False
        while i < len(src):
            ch = src[i]
            if quote:
                if escaped:
                    escaped = False
                elif ch == "\\":
                    escaped = True
                elif ch == quote:
                    quote = None
            else:
                if ch in "'\"": quote = ch
                elif ch == "(": depth += 1
                elif ch == ")":
                    depth -= 1
                    if depth == 0:
                        break
            i += 1
        block = src[start:i + 1]
        strings = []
        for m in re.finditer(r"(['\"])((?:\\.|(?!\1).)*)\1", block, re.S):
            value = m.group(2).replace("\\'", "'").replace('\\"', '"').replace("\\n", " ")
            strings.append(value)
        idx_m = re.search(r",\s*(\d+)\s*\)$", block.strip(), re.S)
        if strings:
            q, options = strings[0], strings[1:]
            correct = int(idx_m.group(1)) if idx_m and options else 0
            cards.append((q, options, correct))
        pos = i + 1
    return cards


story.extend([
    Paragraph("APPENDIX B", styles["ScreenNo"]),
    Paragraph("General knowledge question bank", styles["Appendix"]),
    Paragraph("Question, visible options and correct answer. Options may be shuffled at runtime.", styles["Body"]),
])
for i, (question, options, correct) in enumerate(gk_cards_from_dart(), 1):
    option_text = " · ".join(options)
    answer = options[correct] if options and correct < len(options) else "Dynamic"
    story.append(KeepTogether([
        Paragraph(f"{i}. {esc(question)}", styles["Copy"]),
        Paragraph(f"Options: {esc(option_text)}<br/>Correct: {esc(answer)}", styles["Meta"]),
    ]))

doc.build(story)
print(OUT)
