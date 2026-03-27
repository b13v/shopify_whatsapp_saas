# Design System — Shopify WhatsApp SaaS

## Product Context
- **What this is:** A Shopify app that sends WhatsApp order notifications to merchants' customers when they place orders.
- **Who it's for:** Shopify store owners who want to keep customers informed via WhatsApp.
- **Space/industry:** Shopify app ecosystem, WhatsApp Business API, SaaS notifications.
- **Project type:** Merchant dashboard (settings + message history + analytics).

## Aesthetic Direction
- **Direction:** Warm Utility — clean and functional like a well-made merchant tool, with subtle warmth borrowed from WhatsApp's brand. Not playful, not corporate.
- **Decoration level:** Minimal. Typography and whitespace do the heavy lifting. WhatsApp green accent is the only decorative element, and it earns its place because it's the product's identity.
- **Mood:** A craftsman's workbench. Professional, efficient, but not cold. The merchant should feel like they're using a tool someone cared about building.
- **Reference sites:** [Shopify Polaris](https://polaris.shopify.com), Wati.io, Interakt.ai

## Typography
- **Display/Hero:** Satoshi — geometric sans-serif with personality. Friendly without being toy-like. Used for shop domain (header h1), page titles, stat values.
  - Why: Different from the Inter/Roboto every Shopify app uses. Warm geometry fits WhatsApp's brand.
- **Body:** DM Sans — clean, readable at small sizes, excellent tabular numbers for data tables.
  - Why: Crisp at 13-14px (table cells, form labels). Good weight range (400-700) for UI hierarchy.
- **Mono:** JetBrains Mono — phone numbers, order IDs, webhook IDs, technical identifiers.
  - Why: Clear distinction between data and prose. Familiar to developer-audience merchants.
- **UI/Labels:** DM Sans (same as body).
- **Loading:** Google Fonts CDN (Satoshi + DM Sans). JetBrains Mono via Google Fonts or self-hosted.
- **Fallback:** system-ui, sans-serif.
- **Scale:**

| Token  | Size  | Weight | Role                |
|--------|-------|--------|---------------------|
| display-xl | 48px | 900 | Shop domain in header |
| display-lg | 28px | 700 | Page titles          |
| display-md | 20px | 500 | Subheadings          |
| body    | 15px | 400 | Body text, paragraphs |
| ui      | 14px | 500 | Form labels, table data |
| ui-sm   | 13px | 600 | Badges, metadata      |
| caption | 12px | 400 | Hints, timestamps    |
| mono    | 14px | 400 | Phone numbers, IDs   |

## Color
- **Approach:** Restrained. 1 accent (WhatsApp green) + neutral grays. Semantic colors for status only.
- **Primary:** `#25D366` (WhatsApp green) — active nav, CTAs, success states, focus rings. Used sparingly.
- **Secondary:** `#128C7E` (WhatsApp teal) — hover states, secondary accents.
- **Accent light:** `#DCF8C6` (WhatsApp light green) — subtle backgrounds when needed.
- **Neutrals:** Tailwind gray scale (gray-50 through gray-900).
  - Background: `#F9FAFB` (gray-50)
  - Surface: `#FFFFFF` (white)
  - Text primary: `#111827` (gray-900)
  - Text secondary: `#6B7280` (gray-500)
  - Text muted: `#9CA3AF` (gray-400)
  - Border: `#E5E7EB` (gray-200)
  - Border light: `#F3F4F6` (gray-100)
- **Semantic:**
  - Success: bg `#D1FAE5` (green-100), text `#065F46` (green-800)
  - Error: bg `#FEE2E2` (red-100), text `#991B1B` (red-800)
  - Warning: bg `#FEF3C7` (amber-100), text `#92400E` (amber-800)
  - Info: bg `#DBEAFE` (blue-100), text `#1E40AF` (blue-800)
- **Dark mode:** Not in scope for MVP.

## Spacing
- **Base unit:** 8px.
- **Density:** Comfortable. Not cramped like data tools, not spacious like marketing sites. Matches Polaris spacing.
- **Scale:**

| Token | Value | Usage                          |
|-------|-------|--------------------------------|
| 2xs   | 4px   | Tight gaps, badge padding     |
| xs    | 8px   | Input padding, inner spacing  |
| sm    | 12px  | Compact gaps                  |
| md    | 16px  | Standard gaps, cell padding   |
| lg    | 24px  | Section padding, card padding |
| xl    | 32px  | Large section gaps            |
| 2xl   | 48px  | Section separation            |
| 3xl   | 64px  | Major vertical rhythm          |

## Layout
- **Approach:** Grid-disciplined. Standard dashboard pattern (header → KPI cards → table → settings). Polaris-consistent.
- **Grid:** Single column, max-width 1280px, responsive breakpoints at sm (640px), md (768px), lg (1024px).
- **Max content width:** `max-w-7xl` (1280px) for dashboard, `max-w-3xl` (768px) for settings form.
- **Border radius:** Hierarchical scale.
  - sm: 4px — badges, small elements
  - md: 6px — inputs, select menus
  - lg: 8px — cards, containers
  - xl: 12px — modals, large containers
  - full: 9999px — pills, avatar circles

## Motion
- **Approach:** Minimal-functional. Only transitions that aid comprehension.
- **Easing:** enter: ease-out, exit: ease-in, move: ease-in-out.
- **Duration:**
  - Micro (50-100ms): button hover, focus ring appearance
  - Short (150-250ms): flash appear/dismiss, tab indicator slide
  - Medium (250-400ms): skeleton loading → content swap

## Components

### Header (DashboardLayout)
- Shop domain as `<h1>` (Satoshi, 20px, 700 weight)
- "WhatsApp Notifications" as subtitle (DM Sans, 13px, gray-500)
- Tab navigation with green active indicator
- Logout link (secondary button style)
- Skip-to-content link for a11y

### KPI Cards
- White background, 1px gray-200 border, 8px border-radius
- Icon + label + value layout
- Value in Satoshi (22px, 700)
- Grid: 1 col mobile, 2 col tablet, 4 col desktop

### Data Table
- White card container with gray-100 header row
- Uppercase 11px labels, 14px body text
- Status badges (semantic colors, full border-radius)
- Phone numbers in JetBrains Mono
- Filter dropdown in card header

### Empty State
- Chat bubble SVG icon (gray-300)
- Title in 14px semibold
- Description in 13px muted
- Green link to settings page with arrow icon

### Settings Form
- Card with border, header + body sections
- DM Sans 14px labels, DM Sans 14px inputs
- Green focus ring on inputs
- Green primary button
- Muted shop info footer (gray-50 background)

### Alerts
- Rounded-md containers with semantic colors
- Icon + text layout
- Dismiss on click

## Decisions Log
| Date       | Decision                                    | Rationale                                               |
|------------|---------------------------------------------|---------------------------------------------------------|
| 2026-03-27 | Initial design system created                | Created by /design-consultation based on competitive research |
| 2026-03-27 | Satoshi as display font                     | Warm geometric feel that matches WhatsApp brand better than Inter |
| 2026-03-27 | DM Sans as body font                        | Excellent tabular numbers for data tables, crisp at small sizes |
| 2026-03-27 | WhatsApp green as sole color accent          | Instant brand recognition, contextual for a WhatsApp app |
| 2026-03-27 | Warm empty states                           | Differentiates from cold "No data" competitors |
| 2026-03-27 | 8px spacing base                          | Matches Polaris, comfortable for merchant dashboards |
| 2026-03-27 | No dark mode for MVP                        | Scope constraint. Can add CSS custom properties later |
