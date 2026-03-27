# TODOS

## Deferred from Design Review + Eng Review

### 1. Add error handling to LiveAuth DB query
**What:** Wrap `Repo.get_by(Shop, ...)` in LiveAuth in a try/rescue that redirects to `/` on failure.
**Why:** If Postgres is momentarily unavailable, the LiveView crashes with a 500 error. The merchant sees a raw server error page instead of a graceful redirect.
**Pros:** Prevents 500 errors on authenticated pages during DB outages. 3 lines of code.
**Cons:** Masks infrastructure issues (but this is the right layer for graceful degradation).
**Context:** `lib/shopify_whatsapp_web/live/live_auth.ex:13` — the `Repo.get_by` call has no rescue. If the query fails, the LiveView mount crashes.
**Depends on:** None.
**Effort:** human 10min / CC 2min.

### 2. Dashboard loading skeleton
**What:** Replace "Loading..." text with skeleton UI cards and table rows.
**Why:** The loading state is just plain text. For a merchant on a slow connection, this looks broken.
**Pros:** Professional appearance during load. Better perceived performance.
**Cons:** Low priority — the dashboard loads in <100ms locally.
**Context:** `lib/shopify_whatsapp_web/live/dashboard_live.ex:47-50` — the `@loading` branch renders just `<p>Loading...</p>`.
**Depends on:** None.
**Effort:** human 1hr / CC 10min.

### 3. Skip-link for keyboard navigation
**What:** Add a hidden "Skip to content" link at the top of the DashboardLayout.
**Why:** Keyboard-only users have to tab through the entire header to reach content.
**Pros:** Accessibility win for keyboard and screen reader users.
**Cons:** Very small UX improvement.
**Context:** `lib/shopify_whatsapp_web/components/dashboard_layout.ex` — no skip link exists.
**Depends on:** None.
**Effort:** human 15min / CC 3min.

### 4. Mobile nav pattern for 3+ tabs
**What:** When tabs grow beyond 2, implement a hamburger menu or scrollable tab bar.
**Why:** Currently 2 tabs fit on all viewports. Adding a 3rd tab might overflow on mobile.
**Pros:** Future-proofing the navigation.
**Cons:** YAGNI — only needed if more tabs are added.
**Context:** `lib/shopify_whatsapp_web/components/dashboard_layout.ex:32` — nav uses `flex space-x-8` with no overflow handling.
**Depends on:** New authenticated page being added.
**Effort:** human 2hrs / CC 30min.

### 5. Run /design-consultation
**What:** Establish a formal design system with color tokens, typography, spacing scale, and component patterns.
**Why:** No DESIGN.md exists. Color choices are ad hoc. The app layout uses zinc, dashboard uses gray/blue. Adding WhatsApp green without a system creates visual drift.
**Pros:** Prevents visual inconsistency as the app grows. Speeds up future UI work.
**Cons:** Time investment upfront.
**Context:** The eng review identified that the app layout (`app.html.heex`) uses zinc colors while the dashboard uses gray/blue. These are two different visual languages.
**Depends on:** None.
**Effort:** human 2hrs / CC 20min.
