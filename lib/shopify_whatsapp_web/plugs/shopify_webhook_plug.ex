defmodule ShopifyWhatsappWeb.ShopifyWebhookPlug do
  @moduledoc """
  Plug for verifying Shopify webhook HMAC signatures.

  Shopify signs all webhook requests with an HMAC signature in the
  X-Shopify-Hmac-SHA256 header. This plug verifies that signature
  and rejects invalid requests with 401 Unauthorized.

  ## Usage

      plug ShopifyWhatsappWeb.ShopifyWebhookPlug

  The plug reads the webhook secret from:
  `Application.get_env(:shopify_whatsapp, :shopify_webhook_secret)`
  """

  import Plug.Conn

  require Logger

  @doc """
  Initializes the plug with options.

  ## Options
    - `:secret` - Explicit webhook secret (optional, defaults to app config)
  """
  def init(opts), do: opts

  @doc """
  Calls the plug to verify the webhook signature.
  """
  def call(conn, _opts) do
    case get_req_header(conn, "x-shopify-hmac-sha256") do
      [hmac] ->
        if verify_hmac(conn, hmac) do
          conn
        else
          Logger.warning("Invalid webhook HMAC from #{remote_ip(conn)}")
          send_hmac_error(conn)
        end

      [] ->
        Logger.warning("Missing webhook HMAC header from #{remote_ip(conn)}")
        send_hmac_error(conn)
    end
  end

  # Private helpers

  defp verify_hmac(conn, provided_hmac) do
    # Read the raw body
    {:ok, body, _conn} = read_body(conn)

    # Calculate expected HMAC
    secret = webhook_secret()

    calculated_hmac =
      :crypto.mac(:hmac, :sha256, secret, body)
      |> Base.encode64()

    # Constant-time comparison
    Plug.Crypto.secure_compare(calculated_hmac, provided_hmac)
  end

  defp send_hmac_error(conn) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(401, Jason.encode!(%{error: "Unauthorized"}))
    |> halt()
  end

  defp webhook_secret do
    Application.get_env(:shopify_whatsapp, :shopify_webhook_secret) ||
      raise """
      Shopify webhook secret not configured!

      Please set :shopify_webhook_secret in your config:

          config :shopify_whatsapp, :shopify_webhook_secret, "your_webhook_secret"
      """
  end

  defp remote_ip(conn) do
    case get_req_header(conn, "x-forwarded-for") do
      [ip | _] -> ip
      [] -> conn.remote_ip |> :inet.ntoa() |> to_string()
    end
  end
end
