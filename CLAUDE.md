# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Shopify WhatsApp SaaS - A Phoenix/Elixir application for integrating WhatsApp messaging with Shopify stores.

- **Application Module**: `ShopifyWhatsapp`
- **OTP App**: `shopify_whatsapp`
- **Database**: PostgreSQL via Ecto
- **Frontend**: Phoenix LiveView + Tailwind CSS

## Development Commands

### Server
```bash
mix phx.server        # Start Phoenix server (default: http://localhost:4000)
iex -S mix phx.server # Start with IEx console for interactive debugging
```

### Database
```bash
mix ecto.create       # Create database
mix ecto.drop         # Drop database
mix ecto.migrate      # Run migrations
mix ecto.rollback     # Rollback last migration
mix ecto.reset        # Drop, create, and migrate
```

### Testing
```bash
mix test              # Run all tests
mix test test/path/to/test.exs  # Run specific test file
mix test --only test_name       # Run tests matching name
```

### Code Quality
```bash
mix format            # Format code
mix format --check-formatted  # Check if code is formatted
mix compile           # Compile project
```

### Assets
```bash
# Assets are compiled automatically in dev
# For production builds:
mix assets.deploy    # Build and deploy assets
```

## Project Structure

```
lib/shopify_whatsapp/           # Core application logic
  ├── application.ex            # Application entry point
  ├── repo.ex                   # Ecto repository
  └── mailer.ex                 # Mailer module

lib/shopify_whatsapp_web/       # Web layer
  ├── components/              # LiveView components & layouts
  ├── controllers/             # HTTP controllers
  ├── endpoint.ex              # Endpoint configuration
  ├── router.ex                # Routes
  └── telemetry.ex             # Telemetry events

priv/
  ├── repo/migrations/         # Database migrations
  ├── gettext/                 # Translations
  └── static/                  # Static assets

test/                          # Test files
  ├── support/                 # Test helpers (ConnCase, DataCase)
  └── shopify_whatsapp_web/    # Web layer tests

config/                        # Configuration files
  ├── config.exs               # Base config
  ├── dev.exs                  # Development config
  ├── prod.exs                 # Production config
  └── runtime.exs              # Runtime config
```

## Architecture Patterns

### Contexts (Business Logic)
Phoenix contexts organize business logic. Create contexts in `lib/shopify_whatsapp/`:
```elixir
defmodule ShopifyWhatsapp.Example do
  @moduledoc """ Context for example domain logic """
end
```

### Schemas (Database)
Ecto schemas define database tables. Create in `lib/shopify_whatsapp/`:
```elixir
defmodule ShopifyWhatsapp.Example.Schema do
  use Ecto.Schema
  import Ecto.Changeset
end
```

### LiveViews
Real-time UI components. Create in `lib/shopify_whatsapp_web/live/`:
```elixir
defmodule ShopifyWhatsappWeb.ExampleLive do
  use ShopifyWhatsappWeb, :live_view
end
```

## Configuration Notes

- Database settings in `config/dev.exs`
- Default port: 4000
- LiveReload enabled in development

## Design System

Always read DESIGN.md before making any visual or UI decisions.
All font choices, colors, spacing, and aesthetic direction are defined there.
Do not deviate without explicit user approval.
In QA mode, flag any code that doesn't match DESIGN.md.
