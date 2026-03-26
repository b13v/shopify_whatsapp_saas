# Plan: Order Notifications MVP

**Status:** COMPLETE ✅
**Created:** 2026-03-26
**Completed:** 2026-03-26

## Goal
Build the narrowest wedge: Shopify App that sends WhatsApp order status notifications when orders are created/updated.

## Success Criteria ✅
- ✅ Shopify App installs successfully
- ✅ Orders trigger WhatsApp notifications
- ✅ Dashboard shows messages sent, delivery rate, error rate
- ✅ Error handling for timeouts and rate limits

---

## All Phases Complete ✅

**Phase 1: Infrastructure Setup** — Oban, Cloak, Shopify API, WhatsApp client
**Phase 2: Database Schema** — Shops, Messages tables with encryption
**Phase 3: Shopify Integration** — OAuth flow, webhook verification, endpoints
**Phase 4: Order Notification Logic** — Oban worker, templates
**Phase 5: Dashboard** — LiveView with stats and message log
**Phase 6: Error Handling** — Retry logic, idempotent webhooks, telemetry

---

## Files Created (26 total)

**Core Modules:**
- lib/shopify_whatsapp/shop.ex — Shop schema with encrypted access_token
- lib/shopify_whatsapp/message.ex — Message schema with status tracking
- lib/shopify_whatsapp/vault.ex — Cloak AES.GCM encryption vault
- lib/shopify_whatsapp/dashboard.ex — Stats queries and message lists
- lib/shopify_whatsapp/telemetry.ex — Structured logging module

**API Clients:**
- lib/shopify_whatsapp/shopify/api.ex — Shopify Admin API client (orders, webhooks)
- lib/shopify_whatsapp/whatsapp/client.ex — WhatsApp Business API wrapper

**Workers:**
- lib/shopify_whatsapp/workers/order_notification_worker.ex — Oban worker for notifications

**Web Controllers:**
- lib/shopify_whatsapp_web/controllers/install_controller.ex — OAuth install flow
- lib/shopify_whatsapp_web/controllers/webhook_controller.ex — Webhook endpoints with idempotency

**Plugs:**
- lib/shopify_whatsapp_web/plugs/shopify_webhook_plug.ex — HMAC-SHA256 verification

**LiveViews:**
- lib/shopify_whatsapp_web/live/dashboard_live.ex — Dashboard UI with Tailwind CSS

**Migrations:**
- priv/repo/migrations/20260326155429_add_oban_tables.exs
- priv/repo/migrations/20260326160335_create_shops.exs
- priv/repo/migrations/20260326160336_create_messages.exs

---

## Configuration Required

Add these environment variables to `config/dev.exs` or `runtime.exs`:

```elixir
# Shopify App Credentials
config :shopify_whatsapp,
  shopify_api_key: "YOUR_API_KEY",
  shopify_api_secret: "YOUR_API_SECRET",
  shopify_webhook_secret: "YOUR_WEBHOOK_SECRET",
  app_host: "your-app.example.com",
  webhook_base_url: "https://your-app.example.com"

# WhatsApp Business API
config :shopify_whatsapp,
  whatsapp_base_url: "https://graph.facebook.com/v19.0",
  whatsapp_phone_id: "YOUR_PHONE_ID",
  whatsapp_access_token: "YOUR_ACCESS_TOKEN"

# Encryption (production only)
config :shopify_whatsapp, ShopifyWhatsapp.Vault,
  ciphers: [
    default:
      {Cloak.Ciphers.AES.GCM,
       tag: "AES.GCM.V1",
       key: Base.decode64!(System.get_env("CLOAK_KEY")),
       iv_length: 12}
  ]
```

---

## Next Steps for Testing

1. **Set up ngrok** for local development:
   ```bash
   ngrok http 4000
   ```

2. **Create WhatsApp message templates** in Meta Business Suite:
   - `order_confirmation` — variables: order_number, customer_name
   - `order_update` — variables: order_number, customer_name

3. **Install the app** on a test store:
   - Navigate to `/install?shop=your-store.myshopify.com`
   - Complete OAuth flow

4. **Create a test order** in Shopify and verify WhatsApp message is sent

5. **Check the dashboard** at `/dashboard?shop=your-store.myshopify.com`

---

## Architecture Overview

```
┌─────────────────┐     OAuth      ┌──────────────────┐
│   Shopify Store │ ──────────────► │ Install Controller │
└─────────────────┘                 └──────────┬─────────┘
                                                │
                                                ▼
                                          ┌──────────────┐
                                          │ Shops Table  │
                                          │ (encrypted)  │
                                          └──────────────┘

┌─────────────────┐    Webhook    ┌──────────────────┐
│   Shopify       │ ─────────────►│ Webhook Controller│
│   Orders/Create │               │  (HMAC verified)  │
└─────────────────┘               └────────┬─────────┘
                                            │
                                            ▼
                                      ┌──────────────┐
                                      │   Oban Queue │
                                      │   (whatsapp)  │
                                      └──────┬───────┘
                                             │
                                             ▼
                                  ┌──────────────────────┐
                                  │Notification Worker  │
                                  │  - Get shop token    │
                                  │  - Build template    │
                                  │  - Send WhatsApp     │
                                  └──────────────────────┘
```
