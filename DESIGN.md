# Design System: ClashChat

Single source of truth for how ClashChat looks and moves. Code lives in `lib/core` (tokens, theme) and `lib/ui` (component kit). Anything not covered here defaults to restraint.

## 1. Visual Theme & Atmosphere

A debate chamber: ink and paper, one flame. Surfaces are true neutrals, type does the talking, and a single vermilion accent marks the one thing you can act on. Proportions follow 80 / 15 / 5: canvas 80 %, surfaces + hairlines + muted text 15 %, accent 5 %, and typography that does the talking. Density is "daily app balanced" (5/10): generous padding, never cramped, never empty. Variance is moderate (5/10): left-aligned headers, asymmetric hero on Home, strict single column on phones. Motion is fluid but short (5/10): things settle in under 260 ms, nothing loops except the timer under one minute and the typing indicator.

What it is not: a neon AI app or a casino. No glows, no gradient buttons, no emoji as icons, no gold on buttons (gold means rank, never action).

## 2. Color Palette & Roles

Two themes, one personality. Dark is the default.

### Dark ("Ink")
- **Canvas** `#0E0E10` (80 % of every screen). **Surface** `#161618`, **Raised** `#1E1E21`, **Inset** `#09090A` — the 15 %, with hairlines `#28282C` / `#38383E`.
- **Ink** `#F4F2EE` primary text, **Muted** `#ADAAA6`, **Hint** `#88857F`.
- **Flame** `#FF5A3C` — the 5 %. Primary button (text `#1A0A06`), selected nav, progress, the live timer, "Chat" in the wordmark. Soft tint = flame @ 14 %.
- **Sage** `#4ED39A` on `#10342A` — For, strengths, success, Easy.
- **Ember** `#FF7B6B` on `#3D1D1D` — Against, weaknesses, errors, Hard.
- **Amber** `#E0B35C` on `#3A2B10` — warnings, Medium.
- **Sky** `#6FB1FF` on `#132A45` — info, Learning.
- **Gold** `#D9A441` on `#3A2B10` — rank and ranked points only.

### Light ("Paper")
- **Canvas** `#F7F5F0` (warm paper), **Surface** `#FFFFFF`, **Inset** `#ECE9E2`, hairlines `#E3E0D8` / `#CFCBC1`.
- **Ink** `#141317`, **Muted** `#5A5860`, **Hint** `#6B6874`.
- **Flame** darkens to `#C93217`. Primary buttons are **Ink** with paper text; flame marks selection and progress.
- Sage `#1E7B55` on `#DDF1E6`, Ember `#C4381E` on `#FBE2DB`, Amber `#8A6A1C` on `#F6EBCF`, Sky `#2F5FB3` on `#E1E9F8`, Gold `#8A6A1C` on `#F6EBCF`.

### Contrast (WCAG 2.x, computed)
| Theme | Pair | Colors | Ratio |
|---|---|---|---|
| Dark | text | `#F4F2EE` on `#0E0E10` | 17.2:1 |
| Dark | mute | `#ADAAA6` on `#0E0E10` | 8.3:1 |
| Dark | hint | `#88857F` on `#0E0E10` | 5.2:1 |
| Dark | accent | `#FF5A3C` on `#0E0E10` | 6.2:1 |
| Dark | pos | `#4ED39A` on `#0E0E10` | 10.2:1 |
| Dark | neg | `#FF7B6B` on `#0E0E10` | 7.6:1 |
| Dark | warn | `#E0B35C` on `#0E0E10` | 9.9:1 |
| Dark | info | `#6FB1FF` on `#0E0E10` | 8.6:1 |
| Dark | rank | `#D9A441` on `#0E0E10` | 8.6:1 |
| Dark | text on surface | `#F4F2EE` on `#161618` | 16.2:1 |
| Dark | hint on surface | `#88857F` on `#161618` | 4.9:1 |
| Light | text | `#141317` on `#F7F5F0` | 17.0:1 |
| Light | mute | `#5A5860` on `#F7F5F0` | 6.4:1 |
| Light | hint | `#6B6874` on `#F7F5F0` | 5.0:1 |
| Light | accent | `#C93217` on `#F7F5F0` | 4.9:1 |
| Light | pos | `#1E7B55` on `#F7F5F0` | 4.8:1 |
| Light | neg | `#C4381E` on `#F7F5F0` | 4.9:1 |
| Light | warn | `#8A6A1C` on `#F7F5F0` | 4.6:1 |
| Light | info | `#2F5FB3` on `#F7F5F0` | 5.7:1 |
| Light | rank | `#8A6A1C` on `#F7F5F0` | 4.6:1 |
| Light | text on surface | `#141317` on `#FFFFFF` | 18.5:1 |
| Light | hint on surface | `#6B6874` on `#FFFFFF` | 5.4:1 |
| Dark | CTA label on accent | `#1A0A06` on `#FF5A3C` | 6.2:1 |
| Light | CTA label on ink | `#F7F5F0` on `#141317` | 17.0:1 |

All text pairs clear 4.5:1; large display numbers and icons clear 3:1 with margin. Re-run the check whenever a token changes.

### Rank colors (both themes)
Newcomer stone `#9A9794`, Challenger bronze `#C08552`, Debater silver `#B7BEC7`, Orator gold `#D9A441`, Grandmaster platinum `#DCE9F5`. Ranks are drawn with Lucide icons, never emoji.

## 3. Typography Rules

- **Display & UI:** Plus Jakarta Sans, bundled as assets (no runtime fetch, no swap). Headlines use weight 700–800 with tight tracking (−0.02 to −0.035 em). Never above 48 px on phones.
- **Numbers:** JetBrains Mono (bundled) for anything that counts: timers, scores, rank points, usage. Tabular, weight 500–600.
- **Scale** (see `app_typography.dart`): display 48/40/36, headline 32/28/24, title 20/18/16, body 16/14/13, label 14/12/11. Body line-height 1.5, max ~65 characters per line.
- Hierarchy comes from weight and color (Ink vs Ink Muted), not from size jumps.
- **Banned:** Inter, Poppins, Outfit, Roboto defaults, any serif in UI, emoji in text, runtime-fetched fonts.

## 4. Component Stylings

All components live in `lib/ui`. Screens compose them; screens do not invent new button styles.

- **Buttons** (`AppButton`): four variants. *Primary* is the CTA fill (Brass in dark, Ink in light), 52 px tall, radius 14, label 14/600, optional leading Phosphor icon. *Secondary* is Surface with Hairline Strong border. *Ghost* is text only. *Danger* is Terracotta text on Terracotta soft. Press feedback is a 0.98 scale over 90 ms. No gradients, no shimmer, no outer glow. Loading replaces the label with a 16 px progress ring in the label color.
- **Icon buttons** (`AppIconButton`): 44 px hit target, 20 px Lucide icon, circular Surface Raised fill on hover/press only.
- **Cards** (`AppCard`): Surface fill, 1 px Hairline, radius 20, padding 20. Elevation is expressed by surface step, not shadow. Light mode may add a 8% warm shadow at y 6 / blur 20. Interactive cards use `Pressable` for scale feedback.
- **Chips / pills** (`AppPill`): 28 px tall, radius pill, 12/600 label, semantic bg/text pairs above. Optional 14 px leading icon.
- **Inputs**: label above in Ink Muted 12/600, field fill Surface Raised (dark) or Inset (light), radius 14, 1 px Hairline, focus ring 2 px Brass, error text below in Terracotta. No floating labels.
- **Navigation bar**: Surface with top Hairline, Lucide icons, heavier stroke when selected, Brass Soft indicator pill, 12/600 labels.
- **Loaders**: `AppSkeleton` shimmer blocks matching the layout. Circular spinners only inside buttons.
- **Empty states** (`AppEmptyState`): 48 px duotone icon in Ink Hint, title 16/600, one line of body, one Secondary button.
- **Avatars**: Dicebear SVG in a circle with a 2 px ring in the rank color.
- **Score ring**: 8 px stroke, Inset track, Brass fill, JetBrains Mono number centered.

## 5. Layout Principles

- Page gutter 20 px. Section gap 24 px. Related items 12 px. Max content width 560 px on desktop for forms, 960 px for dashboards, centered.
- Home is asymmetric: greeting + avatar row, then a wide rank card beside a narrow usage card, then mode rows as full-width list items with a leading icon tile. No three-equal-cards row.
- Lists use rows with Hairline dividers inside one Surface instead of a card per item.
- One primary action per screen, bottom-anchored on phones.
- Everything collapses to one column under 600 px. No horizontal scrolling on phones.

## 6. Motion & Interaction

- Durations: 90 ms press, 180 ms state change, 260 ms enter. Curve `easeOutCubic`. Nothing linear.
- Screen content enters as a stagger: each block 40 ms after the previous, fade + 8 px rise. Only on first build, never on tab switch.
- Respect `MediaQuery.disableAnimations`.
- Permitted loops: typing indicator dots, timer pulse under 60 s.
- Banned: shimmer sweeps on buttons, aurora blobs, infinite floating, radial glows behind content.

## 7. Icons

Lucide icons via `lucide_icons_flutter`. The regular stroke is the default; the 600-weight stroke (`*Filled` names) marks the selected navigation item and rank emblems. Mapped once in `lib/ui/app_icons.dart`; screens never reference `Icons.*` or `LucideIcons.*` directly.

## 9. Atmosphere, Depth & Motion (v2)

The first pass set tokens and structure. This layer is what makes it feel made.

- **Backdrop** (`AppBackdrop`): every page sits on the canvas plus two faint "stage lights" (flame 8.5 % top-left, sky 4.5 % right, drifting over ~22 s) and a fine film grain (4.5 % white in dark, 3.5 % black in light). Never a visible blob, never neon: at arm's length it reads as a lit room, not a gradient.
- **Glass** (`GlassCard`, `GlassBar`): blur 16–18, fill 72 % (dark) / 80 % (light), hairline, 1 px top highlight. Used for the login card on desktop, floating headers over scrolling content, the scoring overlay and bottom sheets. Not for ordinary cards.
- **Numbers move** (`AnimatedNumber`): points, scores and counts count up in the mono face on first appearance.
- **Big moments** (`ParticleBurst`): a short fall of brass/sage/sky flecks for a score of 70+ or positive ranked points. Once, never looping.
- **Hover** (web/desktop): cards lift 2 px with a brighter hairline and softer shadow; rows tint accent-soft; buttons brighten 6 %. Touch gets press-scale + a light haptic instead.
- **Choreography**: screens enter as one staggered reveal (40 ms per block). Page transitions fade-forward. The splash is the brand animation: the two bubbles fly in and clash, ring + sparks, wordmark cascades letter by letter.
- **Layout classes** (`AppPage`, `AppBreakpoints`): compact < 600 (bottom nav, single column), medium 600–899 (navigation rail, two columns allowed), expanded 900–1199 (sidebar, bento), large ≥ 1200 (sidebar, bento, 1180 max). Content widths: form 560, content 880, wide 1180. Gutters 20 / 24 / 48.
- **Bento** (`Bento`): dashboards are mosaics on wide screens (rank hero 2×, usage 1×, modes, recent debates) and a single priority-ordered column on phones. Rows are intrinsic-height so tiles align.
- **Mobile is primary**: safe areas everywhere, keyboard-aware composers, 44 px targets, bottom sheets with drag handles, blurred bottom nav, pull-to-refresh on lists. Desktop adds, never replaces.

## 8. Anti-Patterns (Banned)

- Emoji anywhere in UI.
- Purple or neon anything. Outer glows. Gradient-filled buttons or text.
- Pure black `#000000`.
- More than one accent color on a screen.
- Three equal cards in a row.
- Hardcoded `Colors.white`, `Colors.grey`, hex literals in screens. Use `context.colors`.
- Inline font sizes. Use `context.text` roles.
- `isDark ? a : b` in widgets. Add a token instead.
- Fake "searching for opponent" states. Say what is happening.
