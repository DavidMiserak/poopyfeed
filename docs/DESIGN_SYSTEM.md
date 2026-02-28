# PoopyFeed Design System

**Last Updated**: 2024-02-09
**Design Direction**: Soft Playful Professional - Warm, trustworthy baby care tracking

## Design Philosophy

**Tone**: Like a caring pediatric nurse - warm, approachable, trustworthy, professional
**Audience**: New parents and professional caregivers managing baby care
**Key Principle**: Delightful interactions without sacrificing usability or accessibility

## Color Palette

### Primary Colors (Peachy Rose)

```css
rose-50:  #fff5f7  /* Lightest background tint */
rose-100: #ffe4e6  /* Subtle highlights */
rose-200: #fecdd3  /* Borders, dividers */
rose-300: #fda4af  /* Hover states */
rose-400: #fb7185  /* Primary brand color */
rose-500: #f43f5e  /* Gradient stops */
rose-600: #e11d48  /* Deeper states */
```

### Accent Colors (Warm Amber/Orange)

```css
amber-400: #fbbf24  /* Cheerful accents */
orange-400: #fb923c /* Gradient middle */
orange-500: #f97316 /* Gradient emphasis */
```

### Neutral Grays

```css
slate-50:  #f8fafc  /* Page backgrounds */
slate-200: #e2e8f0  /* Subtle borders */
slate-600: #475569  /* Secondary text */
slate-700: #334155  /* Body text */
slate-900: #0f172a  /* Headings */
```

### Semantic Colors

```css
emerald-500: #10b981  /* Success states */
red-500:     #ef4444   /* Error states */
```

## Typography

### Font Stack

```css
--font-display: "Fredoka", "Comic Neue", "Quicksand", system-ui, sans-serif;
--font-body: "DM Sans", "Inter", system-ui, -apple-system, sans-serif;
```

### Type Scale

```html
<!-- Headings (Fredoka) -->
<h1 class="font-['Fredoka',sans-serif] text-4xl lg:text-7xl font-bold">
    Hero Title
</h1>
<h2 class="font-['Fredoka',sans-serif] text-3xl font-bold">Section Title</h2>
<h3 class="font-['Fredoka',sans-serif] text-2xl font-bold">Card Title</h3>
<h4 class="font-['Fredoka',sans-serif] text-xl font-bold">Subsection</h4>

<!-- Body (DM Sans) -->
<p class="font-['DM_Sans',sans-serif] text-lg">Large body</p>
<p class="font-['DM_Sans',sans-serif] text-base">Regular body</p>
<p class="font-['DM_Sans',sans-serif] text-sm">Small text</p>
<p class="font-['DM_Sans',sans-serif] text-xs">Caption</p>
```

## Layout Patterns

### Page Wrapper

```html
<!-- Full-page gradient background with decorative blobs -->
<div
    class="min-h-screen relative bg-gradient-to-br from-rose-50 via-amber-50 to-orange-50 px-6 py-12 overflow-hidden"
>
    <!-- Decorative background blobs -->
    <div class="absolute inset-0 opacity-20 pointer-events-none">
        <div
            class="absolute top-20 left-20 w-64 h-64 bg-gradient-to-br from-rose-400 to-amber-400 rounded-full blur-3xl animate-pulse"
        ></div>
        <div
            class="absolute bottom-20 right-20 w-96 h-96 bg-gradient-to-br from-orange-400 to-rose-500 rounded-full blur-3xl animate-pulse"
            style="animation-delay: 1s;"
        ></div>
    </div>

    <!-- Content container -->
    <div class="max-w-6xl mx-auto relative z-10">
        <!-- Page content here -->
    </div>
</div>
```

### Card Component

```html
<!-- Frosted glass card with rose border -->
<div
    class="bg-white/80 backdrop-blur-lg rounded-3xl shadow-2xl p-8 border-2 border-rose-200"
>
    <!-- Card content -->
</div>
```

## Component Patterns

### Primary Gradient Button

```html
<button
    class="group relative px-6 py-3 rounded-xl font-['DM_Sans',sans-serif] font-bold text-white shadow-xl hover:shadow-2xl transition-all duration-300 hover:-translate-y-1 active:translate-y-0 overflow-hidden border-2 border-rose-400"
>
    <span
        class="absolute inset-0 bg-gradient-to-br from-rose-400 via-orange-400 to-amber-400 transition-transform duration-300 group-hover:scale-110"
    ></span>
    <span class="relative z-10">Button Text</span>
</button>
```

### Secondary Button

```html
<button
    class="px-6 py-3 rounded-xl font-['DM_Sans',sans-serif] font-bold text-slate-700 bg-slate-200 hover:bg-slate-300 transition-all duration-300 hover:-translate-y-1 active:translate-y-0"
>
    Cancel
</button>
```

### Form Input

```html
<input
    type="text"
    class="w-full px-4 py-3 border-2 border-slate-200 rounded-xl focus:border-rose-400 focus:ring-4 focus:ring-rose-100 transition-all outline-none text-slate-900 font-['DM_Sans',sans-serif]"
    placeholder="Enter text..."
/>
```

### Radio Button Card (Custom)

```html
<label class="relative cursor-pointer">
    <input type="radio" name="option" value="1" class="peer sr-only" />
    <div
        class="p-4 rounded-xl border-2 border-slate-200 bg-white peer-checked:border-rose-400 peer-checked:bg-gradient-to-br peer-checked:from-rose-50 peer-checked:to-pink-50 transition-all hover:shadow-md"
    >
        <div class="text-center">
            <span class="text-4xl block mb-2">🍼</span>
            <span
                class="font-['DM_Sans',sans-serif] font-semibold text-slate-900"
                >Option</span
            >
        </div>
    </div>
</label>
```

### Error Alert

```html
<div
    class="bg-gradient-to-r from-red-50 to-rose-50 border-l-4 border-red-500 p-4 rounded-xl"
>
    <p
        class="font-['DM_Sans',sans-serif] text-red-700 text-sm font-medium flex items-center gap-2"
    >
        <svg
            class="w-5 h-5 flex-shrink-0"
            fill="currentColor"
            viewBox="0 0 20 20"
        >
            <path
                fill-rule="evenodd"
                d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.28 7.22a.75.75 0 00-1.06 1.06L8.94 10l-1.72 1.72a.75.75 0 101.06 1.06L10 11.06l1.72 1.72a.75.75 0 101.06-1.06L11.06 10l1.72-1.72a.75.75 0 00-1.06-1.06L10 8.94 8.28 7.22z"
                clip-rule="evenodd"
            />
        </svg>
        Error message text
    </p>
</div>
```

### Loading Spinner

```html
<div class="flex items-center justify-center py-20">
    <svg
        class="w-16 h-16 animate-spin text-rose-400"
        fill="none"
        viewBox="0 0 24 24"
    >
        <circle
            class="opacity-25"
            cx="12"
            cy="12"
            r="10"
            stroke="currentColor"
            stroke-width="4"
        ></circle>
        <path
            class="opacity-75"
            fill="currentColor"
            d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
        ></path>
    </svg>
</div>
```

## Animation Guidelines

### Standard Transitions

```css
/* Hover lift */
hover:-translate-y-1 active:translate-y-0 transition-all duration-300

/* Scale on hover */
hover:scale-110 transition-transform duration-300

/* Fade in */
opacity-0 hover:opacity-100 transition-opacity duration-300
```

### Custom Animations (in styles.css)

```css
@keyframes wiggle {
    0%,
    100% {
        transform: rotate(-3deg);
    }
    50% {
        transform: rotate(3deg);
    }
}

@keyframes pulse-ring {
    0% {
        transform: scale(1);
        opacity: 1;
    }
    100% {
        transform: scale(2);
        opacity: 0;
    }
}

@keyframes float {
    0%,
    100% {
        transform: translateY(0px);
    }
    50% {
        transform: translateY(-10px);
    }
}
```

**Usage**:

```html
<span class="animate-wiggle">🍼</span>
<span class="animate-pulse-ring"></span>
<div class="animate-float"></div>
```

## Spacing Scale

Use Tailwind's default spacing scale consistently:

```text
p-2  = 0.5rem (8px)   - Tight internal padding
p-4  = 1rem (16px)    - Standard padding
p-6  = 1.5rem (24px)  - Card padding
p-8  = 2rem (32px)    - Large card padding
p-12 = 3rem (48px)    - Hero/landing sections

gap-2 = 0.5rem  - Tight spacing
gap-4 = 1rem    - Standard spacing
gap-6 = 1.5rem  - Generous spacing
gap-8 = 2rem    - Section spacing
```

## Icon Guidelines

### Emoji Icons

Preferred for playful, friendly UI:

```text
🍼 Feeding
🧷 Diaper
😴 Nap
👶 Baby
❤️  Love/Care
👥 Sharing
✓  Success
⚠️  Warning
```

### SVG Icons

Use for UI controls (back arrows, close buttons, etc.)
All SVG icons should include `aria-hidden="true"` and be decorative-only.

## Accessibility Requirements

1. **Keyboard Navigation**: All interactive elements must be keyboard accessible
2. **Focus Visible**: Use custom focus ring: `focus-visible:outline-rose-400`
3. **ARIA Labels**: All icon-only buttons need `aria-label`
4. **Color Contrast**: Maintain WCAG AA minimum (4.5:1 for body, 3:1 for large text)
5. **Motion**: Respect `prefers-reduced-motion` (handled in styles.css)
6. **Screen Readers**: Use semantic HTML, proper heading hierarchy

## Responsive Breakpoints

```css
/* Mobile first approach */
sm:  640px  /* Small tablets */
md:  768px  /* Tablets */
lg:  1024px /* Laptops */
xl:  1280px /* Desktops */
2xl: 1536px /* Large screens */
```

**Common patterns**:

```html
<!-- Stack on mobile, row on desktop -->
<div class="flex flex-col md:flex-row gap-4">
    <!-- Full width on mobile, constrained on desktop -->
    <div class="w-full md:w-1/2 lg:w-1/3">
        <!-- Hide on mobile, show on desktop -->
        <div class="hidden lg:block"></div>
    </div>
</div>
```

## Component Checklist

When creating new components, ensure:

- [ ] Uses Fredoka for headings, DM Sans for body text
- [ ] Follows color palette (rose/amber/orange gradients)
- [ ] Includes frosted glass cards (`bg-white/80 backdrop-blur-lg`)
- [ ] Has consistent rounded corners (`rounded-xl` or `rounded-3xl`)
- [ ] Implements hover lift animations (`hover:-translate-y-1`)
- [ ] Includes proper ARIA labels and semantic HTML
- [ ] Respects `prefers-reduced-motion`
- [ ] Uses consistent spacing scale (p-4, gap-6, etc.)
- [ ] Has proper focus states (`focus:border-rose-400 focus:ring-4 focus:ring-rose-100`)
- [ ] Works on mobile (test at 375px width minimum)

## File Organization

```text
src/
├── app/
│   ├── components/       # Shared components (header, footer)
│   ├── landing/          # Landing page sections
│   ├── auth/             # Login, signup
│   ├── children/         # Child management + nested tracking
│   └── invites/          # Invite acceptance
├── assets/               # Static assets
└── styles.css            # Global design system CSS
```

## Migration from Hex Codes to Tailwind Classes

**Before**:

```html
<div class="border-2 border-[#fecdd3]">
    <button class="bg-[#fb7185]">
        <span class="text-[#fb923c]"></span>
    </button>
</div>
```

**After**:

```html
<div class="border-2 border-rose-200">
    <button class="bg-rose-400">
        <span class="text-orange-400"></span>
    </button>
</div>
```

## Common Patterns Reference

### Navigation Link

```html
<a
    routerLink="/path"
    class="font-['DM_Sans',sans-serif] text-sm text-slate-600 hover:text-rose-400 transition-colors font-medium inline-flex items-center gap-2"
>
    Link Text
</a>
```

### Back Link with Arrow

```html
<a
    routerLink="/back"
    class="font-['DM_Sans',sans-serif] text-sm text-slate-600 hover:text-rose-400 transition-colors font-medium inline-flex items-center gap-2"
>
    <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path
            stroke-linecap="round"
            stroke-linejoin="round"
            stroke-width="2"
            d="M10 19l-7-7m0 0l7-7m-7 7h18"
        />
    </svg>
    Back
</a>
```

### Status Badge

```html
<span
    class="inline-flex items-center px-3 py-1 rounded-full text-xs font-bold border border-emerald-200 bg-emerald-50 text-emerald-700"
>
    Active
</span>
```

---

**Questions? Issues?**
File an issue or contact the design team. This is a living document - update as patterns evolve!
