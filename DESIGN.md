# Design System: ClashChat

Single source of truth for how ClashChat looks and moves. Code lives in `lib/core` (tokens, theme) and `lib/ui` (component kit). Anything not covered here defaults to restraint.

## 1. Visual Theme & Atmosphere

A debate arena after hours. Violet-black surfaces with real tonal steps, one luminous gold accent used like a trophy, lit by soft gold, violet and ember stage lights, and typography that does the talking. Density is "daily app balanced" (5/10): generous padding, never cramped, never empty. Variance is moderate (5/10): left-aligned headers, asymmetric hero on Home, strict single column on phones. Motion is fluid but short (5/10): things settle in under 260 ms, nothing loops except the timer under one minute and the typing indicator.

What it is not: a neon purple AI app. No glows, no gradient buttons, no emoji as icons, no spinning robots.

## 2. Color Palette & Roles

Two themes, one personality. Dark is the default.

### Dark ("Arena Night")
- **Canvas** `#0D0B12` — scaffold background. Violet-black, never pure black.
- **Surface** `#17141D` — cards, sheets. **Surface Raised** `#211D2A` — nested panels, AI bubbles, inputs. **Inset** `#07060A` — recessed wells.
- Cards carry a 5 % top-light so they read as lit objects, not flat rectangles.
- **Ink** `#F5F1EA` primary text. **Ink Muted** `#B8B1AA`. **Ink Hint** `#857E88` (4.5:1 on canvas).
- **Hairline** `#2C2736`, **Hairline Strong** `#3E3749` — visible, not ghostly.
- **Gold** `#F0B94B` — the accent. Text on gold is `#1C1406`. **Gold Soft** gold @ 16 %.
- **Sage** `#5BD29B` on `#123A2E` — For, strengths, success, Easy.
- **Ember** `#FF8A6A` on `#432119` — Against, weaknesses, errors, Hard.
- **Amber** `#F5C76A` on `#3F2E10` — warnings, Medium, ranked points.
- **Sky** `#7FB4FF` on `#172A47` — info, Learning.
- **Violet** `#7C5CFF` — ambience only (backdrop light), never chrome.

### Light ("Arena Day")
- **Canvas** `#F7F4EE` (warm paper), **Surface** `#FFFFFF`, **Inset** `#ECE7DE`.
- **Ink** `#171320`, **Ink Muted** `#5B5566`, **Ink Hint** `#7A7484`.
- **Hairline** `#E3DDD2`, **Hairline Strong** `#CFC7BA`.
- **Gold** darkens to `#B47F1E` for text and icons. Primary buttons are **Ink** with paper text.
- Sage `#1F7A55` on `#DDF3E8`, Ember `#B8442B` on `#FBE3DD`, Amber `#946011` on `#FBEFD5`, Sky `#2F62B5` on `#E1EAF9`.

### Rank colors (both themes)
Newcomer stone `#9A958F`, Challenger bronze `#C98A4B`, Debater silver `#B9C2CC`, Orator gold `#F0B94B`, Grandmaster ice `#D7ECFA`. Ranks are drawn with Lucide icons, never emoji.

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

- **Backdrop** (`AppBackdrop`): every page sits on the canvas plus four slow "stage lights" (gold 22 %, violet 16 %, ember 10 %, sky 7 %, drifting over ~22 s) and a fine film grain (4.5 % white in dark, 3.5 % black in light). Never a visible blob, never neon: at arm's length it reads as a lit room, not a gradient.
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
