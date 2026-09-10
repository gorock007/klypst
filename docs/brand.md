# Brand Guidelines --- Clipboard Utility

**Status:** Product + visual design source of truth\
**Applies to:** iOS app, onboarding, App Store assets, landing page,
launch/social assets\
**Brand direction:** Warm, expressive, premium utility\
**Updated:** 10 September 2026

## 1. Brand idea

This product gives the iPhone clipboard a memory.

**Core experience:** Copy → remember → retrieve → paste.

**Core promise:** The thing you copied isn't gone.

**Primary tagline:** **Your clipboard remembers.**

The product is a tiny utility that solves one annoying problem extremely
well. It is not a productivity suite, knowledge-management system, AI
product, or complicated clipboard database.

Use this file with `PRD.md` and `architecture.md`. PRD defines what the
product does; architecture defines how it is built; this file defines
how it looks, feels, speaks, and presents itself.

## 2. Personality

The brand should feel warm, clever, useful, fast, friendly, slightly
playful, modern, premium, private, calm and confident.

Target balance: **80% refined utility + 20% personality.**

Avoid corporate, enterprise, cyberpunk, hacker-themed, overly technical,
childish, toy-like, cluttered, generic SaaS, "productivity-bro," sterile
Apple imitation, or stereotypical AI aesthetics.

## 3. Central visual metaphor --- The Stack

Do not use a bookmark as the primary logo metaphor. A bookmark
communicates saving a page for later.

Our visual metaphor is a **stack of softly layered cards/sheets**:

-   front card = current/retrieved clip;
-   cards behind = clipboard history;
-   layering = previous items remain available;
-   moving a rear card forward = retrieving an older copy.

Extend this metaphor into product motion and marketing. New clips can
conceptually join the front of the stack; retrieving an old clip brings
it forward.

## 4. Mascot

The mascot is a friendly stack-of-cards character.

Construction: - one dominant rounded front card; - two subtly offset
cards behind; - soft rounded corners; - slight dimensional depth; -
optional subtle playful tilt; - large expressive eyes; - simple
eyebrows; - friendly smile.

No arms, legs, hands, clothing, hats, or accessories.

The expression should communicate **"I've got it"**, not
children's-cartoon excitement.

Use the full mascot for onboarding, landing hero, empty states, success
moments, App Store marketing and launch graphics. Do not put it on every
app screen.

## 5. App icon

Use one centered stack mascot with the front card dominant and two rear
cards subtly visible. Aim for roughly 60--70% visual occupancy with
generous breathing room.

Use: - warm off-white/cream background; - coral-orange mascot; - strong
silhouette; - smooth surfaces; - gentle beveling; - restrained depth; -
soft upper-left lighting; - subtle shadow; - highly readable face.

Avoid heavy 3D, glossy-plastic excess, photorealism, chrome, neon,
complex gradients, noisy grain, or busy backgrounds.

**Marketing can be textural. The app icon should be clean.**

Supply edge-to-edge icon artwork and do not bake a fake rounded-square
icon container into the artwork. Let iOS apply the system mask.

## 6. Color system

Working tokens:

``` css
--brand-orange: #FF5A36;
--brand-orange-deep: #E94A2B;
--brand-orange-soft: #FF8A6A;
--brand-cream: #F8F5EF;
--brand-warm-white: #FFFDF9;
--brand-charcoal: #191919;
--brand-black: #0B0B0B;
--neutral-700: #4A4845;
--neutral-500: #77736E;
--neutral-300: #C9C4BC;
--neutral-150: #E8E3DB;
--neutral-100: #F2EEE8;
```

These are working values until sampled from the approved master artwork.
Centralize them as design tokens.

Primary combination: **cream + orange + charcoal**.

Secondary: **charcoal/black + warm white + orange accent**.

Orange identifies the brand but should not cover the entire product UI.
Use it for the mascot, selected/important states, primary brand moments
and small emphasis.

### Marketing texture

Use atmospheric coral/orange airbrush, blur and restrained grain for
hero art, social cards, App Store editorial assets and section
transitions. Never let texture reduce readability.

## 7. Typography

### iOS

Use Apple's system typography through native SwiftUI semantic styles. Do
not bundle a custom font just to brand the app. Preserve Dynamic Type
and accessibility.

### Web

Use a modern system/neo-grotesk stack:

``` css
font-family: -apple-system, BlinkMacSystemFont, "SF Pro Display",
             "SF Pro Text", system-ui, sans-serif;
```

Do not redistribute Apple font files.

Headlines: large, short, confident, slightly tight, generous whitespace.

Body: highly legible, restrained width, comfortable line-height.

## 8. Layout language

The brand should feel editorial rather than dashboard-like.

Use: - large type; - generous whitespace; - occasional asymmetry; -
rounded art/image panels; - strong hierarchy; - negative space; -
occasional dark sections; - large mascot moments; - modular editorial
compositions.

Avoid making every section three identical SaaS feature cards.

## 9. Shape language

Use soft rectangles, rounded cards, stacked sheets, circular controls
and large editorial panels. Corners should feel soft but not bubbly.

Repeat stack/card geometry subtly throughout onboarding, screenshots and
marketing.

Avoid excessive pills. Use pills only for compact filters, labels,
segmented controls and suitable CTAs.

## 10. Depth and texture

Depth communicates hierarchy, not decoration.

Use soft low-opacity shadows and broad blur. Mascot/marketing art may
use stronger studio shadows. App UI should prefer native materials,
separators and spacing.

Avoid glowing cards, dramatic shadows, fake neumorphism and glass
everywhere.

Texture belongs in brand/marketing surfaces, not history lists, search
results, settings or text-heavy UI.

## 11. Motion

Motion reinforces the stack:

-   **Add:** new card slides onto front.
-   **Retrieve:** rear card moves forward.
-   **Copy:** selected card subtly lifts/snaps.
-   **Delete:** card softly exits.
-   **Pin:** card settles into a stable state.

Motion should be quick, tactile, subtle and slightly springy. No
confetti, long animations or mascot dancing. Respect Reduce Motion.

## 12. iOS app direction

The app is cleaner than the website.

Think: **Apple-native utility with a distinct warm personality.**

Main history prioritizes: 1. Search. 2. Recent clips. 3. Pinned clips.
4. Fast copy interaction.

Content should dominate clip rows/cards. Do not put mascot faces on clip
rows.

Use SF Symbols for standard
text/link/image/pin/search/trash/share/settings/copy actions.

Orange can communicate selection, copy success, active filters and
brand-level CTAs. Routine UI remains native and restrained.

### Dark mode

Design intentionally: - near-black background; - warm-white text; -
elevated dark surfaces; - accessible orange accents; - orange mascot.

Do not merely invert the light theme.

## 13. Onboarding

Keep onboarding short and behavioral.

### Screen 1

**Your clipboard remembers.**

Save the things you copy and bring them back when you need them.

### Screen 2

**Nothing useful gets buried.**

Find recent text, links and images in seconds.

### Screen 3

**Keep it one press away.**

Set up the Action Button for the fastest path back to recent clips.

### Screen 4

**Private by default.**

Your clipboard history stays on your iPhone in V1. No account. No
tracking.

CTA: **Get started**

Only claim behavior the shipping implementation actually supports.

## 14. Voice and copy

Voice: direct, human, concise, slightly playful, never over-clever.

Good: - "Your clipboard remembers." - "Copied." - "Nothing here yet." -
"Copy something and save it. It'll be here when you need it."

Avoid: - "Supercharge your productivity with the ultimate AI-powered
clipboard solution." - technical database language; - exaggerated
productivity claims.

Supporting lines: - Copy now. Find it later. - The things you copy,
still within reach. - Your recent copies. One press away. - Copy once.
Keep it around. - Find what you copied. - A memory for your clipboard. -
Private clipboard history for iPhone.

Use one strong line per composition.

## 15. Landing page objective

Within five seconds the visitor should understand: 1. what it is; 2. why
it matters; 3. how fast retrieval is; 4. that clipboard data is
private/local in V1; 5. how to get the app.

The page is marketing, not documentation.

## 16. Landing page structure

### Navigation

Minimal. Brand/mark left; How it works, Privacy, FAQ, Download right.

### Hero

Headline:

# Your clipboard remembers.

Supporting:

**Save the things you copy. Find them again in seconds.**

Primary CTA: **Download for iPhone**

Secondary CTA: **See how it works**

Visual: large stack mascot + real iPhone product mockup + restrained
orange atmospheric field on cream.

Lead with the benefit. "Clipboard history for iPhone" can support
SEO/explanation.

### Problem

Use short editorial copy:

> You copy an address.\
> Then a link.\
> Then a phone number.\
> And the address is gone.\
> It shouldn't be.

Then explain that the app gives useful copied things somewhere to stay.

### Product demonstration

This is the most important proof section.

Show the real flow:

``` text
Copy something
      ↓
Save/capture it
      ↓
Need it again?
      ↓
Action Button
      ↓
Choose previous clip
      ↓
Paste
```

Prefer real product video/mockups over abstract illustration.

### Stack section

Headline:

**Your copies, still in the stack.**

Show text, URL and image cards. Animate a new card arriving and an old
card moving forward.

### Action Button

Headline:

# One press away.

Show physical iPhone side → Action Button → supported recent-clip
experience → select → copied.

Never depict unsupported behavior.

### Privacy

Give privacy a major dark/high-contrast section.

Headline:

# Your clipboard is yours.

Supporting:

> Clipboard history can contain private messages, addresses, links and
> work information. V1 keeps your history on your iPhone.

Three points: - No account. - No tracking. - No developer cloud.

Keep privacy confident, not fear-based.

### Features

Keep compact: - Text, links and images. - Fast local search. - Pin
important clips. - Action Button. - Share Sheet. - Retention controls. -
Delete everything anytime. - Works offline.

### Free V1

Headline:

# Free to start. No catch.

Copy:

> We're launching the first version free while we build the best
> clipboard experience for iPhone.

Do not promise future pricing.

### Final CTA

Large mascot/brand composition.

# Copy something worth keeping.

**Download for iPhone**

### Footer

Privacy Policy, Support, Terms if needed, App Store and copyright.

## 17. Landing page visual rhythm

Use three intentional modes:

-   **Clean:** cream + charcoal + product.
-   **Atmospheric:** coral/orange blurred grain.
-   **Dark:** near-black + cream + orange.

Suggested sequence:

``` text
Hero          → Cream
Problem       → Cream
Demo          → Dark
Stack         → Orange atmospheric
Action Button → Cream
Privacy       → Dark
Features      → Cream
Final CTA     → Orange atmospheric
```

Do not randomly alternate backgrounds.

## 18. Photography/art direction

If photography is used, make it candid, editorial, human, cinematic,
contemporary and slightly grainy.

Good: - person using iPhone; - close hand/device interactions; -
motion-blurred life/city moments; - situations involving fleeting
information.

Avoid generic office teams, laptop-pointing stock photos, startup
meetings, fake business portraits and futuristic AI imagery.

The photography idea is: **life moves quickly; useful things shouldn't
disappear.**

## 19. App Store screenshots

Treat screenshots as advertising.

Suggested sequence: 1. **Your clipboard remembers.** --- hero UI +
mascot. 2. **Find what you copied.** --- history/search. 3. **One press
away.** --- Action Button. 4. **Text. Links. Images.** 5. **Keep the
important ones close.** --- pins. 6. **Private by default.** --- local
privacy.

Use large readable copy.

## 20. Accessibility

Brand expression never overrides accessibility.

Require: - sufficient contrast; - Dynamic Type; - VoiceOver; - Reduce
Motion; - non-color-only state; - meaningful labels; - readable text
over textures; - accessible tap targets.

If orange/cream fails text contrast, use charcoal/black text.

## 21. Responsive web

Mobile-first.

On narrow screens: - single-column hero; - large headline without
overflow; - readable product demo; - editorial grids stack; - mascot
never obscures copy; - comfortable CTA targets; - intentional
atmospheric crops.

Do not simply shrink desktop compositions.

## 22. Web implementation

Prefer semantic HTML, modern CSS, restrained JS, responsive images,
AVIF/WebP where suitable, SVG/vector brand assets, lazy loading,
reduced-motion handling and excellent Core Web Vitals.

Animations are progressive enhancement. The page must remain
understandable with motion disabled.

## 23. Asset hierarchy

Maintain canonical assets:

``` text
/brand
  /logo
    mascot-stack-master
    mascot-stack-flat
    mark-monochrome
  /icon
    app-icon-master
  /textures
    orange-airbrush-01
    orange-airbrush-02
  /marketing
    hero
    app-store
  /product
    screenshots
    action-button-demo
```

Never regenerate/reinterpret the mascot independently for every page.

## 24. Logo variants

Maintain: - **Primary:** orange stack mascot on cream. - **Reverse:**
orange stack mascot on charcoal. - **Monochrome:** charcoal stack mark
on cream. - **Small-size:** simplified stack silhouette/reduced facial
detail if necessary.

Do not randomly recolor the mascot.

## 25. Agent prohibitions

Do not: - revert to a bookmark as the main metaphor; - make
black-and-white the primary identity; - add unrelated blue/purple SaaS
gradients; - make the whole UI orange; - put grain everywhere; - make it
childish; - animate the mascot constantly; - use emojis as product
icons; - use glassmorphism everywhere; - imitate competitor UI; - copy
Apple marketing one-for-one; - add AI visual language; - use generic
stock illustrations; - fill whitespace unnecessarily; - overuse
cards/pills; - sacrifice speed/usability for branding.

## 26. Design decision test

Before adding something, ask:

1.  Does it make the product faster to understand?
2.  Does it reinforce memory, stack, or retrieval?
3.  Does it feel like a premium iPhone utility?
4.  Is it still useful without the decoration?
5.  Is it readable at small sizes?

If not, remove it.

## 27. North star

The product should feel like:

> **Apple forgot to build clipboard history, and a small independent
> team built the missing utility with more personality than Apple would
> have.**

Not an Apple clone. Not a generic indie utility.

A small, native, delightful product with a recognizable character and an
extremely clear purpose.

## 28. Brand summary

**Product:** Private clipboard history for iPhone.\
**Core promise:** Get back the things you copied.\
**Primary tagline:** **Your clipboard remembers.**\
**Visual metaphor:** Stack of recent copies.\
**Mascot:** Friendly coral-orange stack-of-cards character.\
**Primary color:** Warm coral orange.\
**Foundation:** Warm cream + charcoal.\
**Marketing:** Editorial typography, orange airbrush/grain, human
photography, bold modular layouts.\
**Product UI:** Native, quiet, fast, accessible.\
**Personality:** Warm, clever, premium, useful.\
**Privacy:** Local-first, communicated confidently.\
**V1:** Free.\
**Brand rule:** **Personality lives around the utility; it must never
get in the way of the utility.**
