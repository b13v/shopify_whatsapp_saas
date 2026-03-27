defmodule ShopifyWhatsappWeb.Router do
  use ShopifyWhatsappWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {ShopifyWhatsappWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :authenticated do
    plug :browser
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", ShopifyWhatsappWeb do
    pipe_through :browser

    get "/", PageController, :home
    get "/install", InstallController, :index
    get "/install/callback", InstallController, :callback
    delete "/logout", SessionController, :delete
  end

  scope "/", ShopifyWhatsappWeb do
    pipe_through :authenticated

    live "/dashboard", DashboardLive, :index
    live "/dashboard/settings", SettingsLive, :index
  end

  scope "/webhooks", ShopifyWhatsappWeb do
    pipe_through :api

    post "/shopify/orders/create", WebhookController, :orders_create
    post "/shopify/orders/updated", WebhookController, :orders_updated
  end

  if Application.compile_env(:shopify_whatsapp, :dev_routes) do
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      get "/login", ShopifyWhatsappWeb.DevLoginController, :index
      live_dashboard "/dashboard", metrics: ShopifyWhatsappWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
