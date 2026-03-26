defmodule ShopifyWhatsapp.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      ShopifyWhatsappWeb.Telemetry,
      ShopifyWhatsapp.Repo,
      {DNSCluster, query: Application.get_env(:shopify_whatsapp, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: ShopifyWhatsapp.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: ShopifyWhatsapp.Finch},
      # Start Oban for background job processing
      {Oban, Application.get_env(:shopify_whatsapp, Oban)},
      # Start a worker by calling: ShopifyWhatsapp.Worker.start_link(arg)
      # {ShopifyWhatsapp.Worker, arg},
      # Start to serve requests, typically the last entry
      ShopifyWhatsappWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: ShopifyWhatsapp.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    ShopifyWhatsappWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
