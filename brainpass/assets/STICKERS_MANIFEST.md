# Nupo sticker art manifest

The kid lock's tile system (`ShapeTileView`) draws branded geometric shapes by
default, and **automatically upgrades to illustrations** when a PNG exists at:

```
assets/stickers/<name>.png     (bundle by adding `assets/stickers/` to pubspec)
```

No code changes needed — drop the files, rebuild, done.

## Spec (all files)
- **PNG with transparent background**, 512×512
- Single centered subject, ~8% padding on all sides
- **Style:** flat, rounded, thick shapes; soft 2-tone shading; friendly faces
  where applicable — match the Nupo owl mascot's look (`assets/mascot_opening.png`
  is the style reference). No outlines thinner than ~8px at 512px. No text.
- Palette: lean on the app's tile colours — coral `#FF7A7A`, teal `#35C9B0`,
  amber `#FFB020`, violet `#9B7BFF`, sky `#57B9FF`, lime `#7ED957`,
  pink `#FF8FD1` — plus the brand purple `#5A32E9` / yellow `#FFC117`.

## Set 1 — counting & memory & odd-one-out items (highest impact, 12 files)
| file | subject |
|---|---|
| fox.png | sitting fox |
| owl.png | mini owl (mascot's little sibling) |
| cat.png | happy cat |
| dog.png | puppy |
| bunny.png | rabbit |
| bear.png | teddy-ish bear |
| fish.png | round fish |
| star.png | chunky star with face |
| apple.png | apple |
| icecream.png | ice-cream cone |
| balloon.png | balloon |
| rocket.png | toy rocket |

## Set 2 — celebration & UI garnish (6 files, optional)
| file | subject |
|---|---|
| trophy.png | gold trophy |
| medal.png | star medal |
| flame.png | friendly streak flame |
| sparkle.png | four-point sparkle |
| crown.png | small crown |
| confetti.png | confetti burst |

Prompt suggestion (for an image model / designer):
"Flat vector sticker of a <subject>, cute rounded kawaii style, thick simple
shapes, soft two-tone shading, friendly face, vibrant <colour> palette,
transparent background, centered, children's education app, matches a playful
purple owl mascot brand."
