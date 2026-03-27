defmodule ShopifyWhatsappWeb.InstallController do
  use ShopifyWhatsappWeb, :controller

  require Logger

  @doc """
  Initiates the Shopify OAuth install flow.

  Redirects to Shopify's authorization page with the app's API key and scopes.
  """
  def index(conn, %{"shop" => shop_domain}) do
    # Validate shop domain format
    if valid_shop_domain?(shop_domain) do
      # Normalize the shop domain
      normalized_shop = ShopifyWhatsapp.Shop.normalize_domain(shop_domain)

      # Build the authorization URL
      auth_url = build_auth_url(normalized_shop)

      redirect(conn, external: auth_url)
    else
      conn
      |> put_status(:bad_request)
      |> put_resp_content_type("text/html")
      |> send_resp(
        400,
        "<html><body><h1>Invalid shop domain format</h1><p>Shop domain must be in format: your-store.myshopify.com</p></body></html>"
      )
    end
  end

  @doc """
  Handles the OAuth callback from Shopify.

  Exchanges the temporary code for a permanent access token and stores the shop.
  """
  def callback(conn, %{"shop" => shop_domain, "code" => code, "hmac" => hmac}) do
    # Verify HMAC signature
    if verify_hmac(conn.query_params, hmac) do
      # Exchange code for access token
      case exchange_code_for_token(shop_domain, code) do
        {:ok, access_token} ->
          # Store or update the shop
          normalized_shop = ShopifyWhatsapp.Shop.normalize_domain(shop_domain)

          case upsert_shop(normalized_shop, access_token) do
            {:ok, shop} ->
              # Register webhooks for this shop
              register_webhooks(shop, access_token)

              # Store shop in session and redirect to dashboard
              conn
              |> put_session("shop_domain", normalized_shop)
              |> put_flash(:info, "App installed successfully!")
              |> redirect(to: "/dashboard")

            {:error, changeset} ->
              Logger.error("Failed to upsert shop: #{inspect(changeset.errors)}")

              conn
              |> put_status(:internal_server_error)
              |> put_resp_content_type("text/html")
              |> send_resp(
                500,
                "<html><body><h1>Installation Failed</h1><p>Could not save shop data. Please try again.</p></body></html>"
              )
          end

        {:error, reason} ->
          Logger.error("Failed to exchange code for token: #{inspect(reason)}")

          conn
          |> put_status(:internal_server_error)
          |> put_resp_content_type("text/html")
          |> send_resp(
            500,
            "<html><body><h1>Authentication Failed</h1><p>Could not authenticate with Shopify. Please try again.</p></body></html>"
          )
      end
    else
      conn
      |> put_status(:unauthorized)
      |> put_resp_content_type("text/html")
      |> send_resp(
        401,
        "<html><body><h1>Unauthorized</h1><p>Invalid signature.</p></body></html>"
      )
    end
  end

  def callback(conn, _params) do
    conn
    |> put_status(:bad_request)
    |> put_resp_content_type("text/html")
    |> send_resp(
      400,
      "<html><body><h1>Bad Request</h1><p>Missing required parameters.</p></body></html>"
    )
  end

  # Private helpers

  defp valid_shop_domain?(shop) do
    case Regex.run(~r/^[a-zA-Z0-9][a-zA-Z0-9\-]*\.myshopify\.com$/, shop) do
      nil -> false
      _ -> true
    end
  end

  defp build_auth_url(shop_domain) do
    api_key = shopify_api_key()
    scopes = shopify_scopes()
    redirect_uri = build_redirect_uri(shop_domain)

    query =
      URI.encode_query(%{
        client_id: api_key,
        scope: scopes,
        redirect_uri: redirect_uri,
        response_type: "code",
        state: generate_state()
      })

    "https://#{shop_domain}/admin/oauth/authorize?#{query}"
  end

  defp build_redirect_uri(_shop_domain) do
    # In production, this should be your app's actual domain
    host = Application.get_env(:shopify_whatsapp, :app_host, "localhost:4000")
    scheme = if Application.get_env(:shopify_whatsapp, :https?), do: "https", else: "http"
    "#{scheme}://#{host}/install/callback"
  end

  defp exchange_code_for_token(shop_domain, code) do
    api_key = shopify_api_key()
    api_secret = shopify_api_secret()
    _redirect_uri = build_redirect_uri(shop_domain)

    url = "https://#{shop_domain}/admin/oauth/access_token"

    body = %{
      client_id: api_key,
      client_secret: api_secret,
      code: code
    }

    case Req.post(url, json: body) do
      {:ok, %{status: 200, body: %{"access_token" => token}}} ->
        {:ok, token}

      {:ok, %{body: response_body}} ->
        {:error, {:token_exchange_failed, response_body}}

      {:error, reason} ->
        {:error, {:request_failed, reason}}
    end
  end

  defp verify_hmac(params, provided_hmac) do
    # Remove hmac from params before calculating
    params_to_sign =
      params
      |> Map.delete("hmac")
      |> Enum.sort_by(fn {k, _v} -> k end)
      |> Enum.map(fn {k, v} -> "#{k}=#{v}" end)
      |> Enum.join("&")

    # Calculate HMAC
    calculated_hmac =
      :crypto.mac(:hmac, :sha256, shopify_api_secret(), params_to_sign)
      |> Base.encode16(case: :lower)

    # Constant-time comparison
    Plug.Crypto.secure_compare(calculated_hmac, provided_hmac)
  end

  defp upsert_shop(shop_domain, access_token) do
    attrs = %{
      shop_domain: shop_domain,
      plain_token: access_token
    }

    case ShopifyWhatsapp.Repo.get_by(ShopifyWhatsapp.Shop, shop_domain: shop_domain) do
      nil ->
        ShopifyWhatsapp.Shop.create_changeset(attrs)
        |> ShopifyWhatsapp.Repo.insert()

      shop ->
        ShopifyWhatsapp.Shop.update_changeset(shop, attrs)
        |> ShopifyWhatsapp.Repo.update()
    end
  end

  defp generate_state do
    :crypto.strong_rand_bytes(16) |> Base.encode16(case: :lower)
  end

  defp shopify_api_key do
    Application.get_env(:shopify_whatsapp, :shopify_api_key)
  end

  defp shopify_api_secret do
    Application.get_env(:shopify_whatsapp, :shopify_api_secret)
  end

  defp shopify_scopes do
    # Scopes needed for order notifications
    [
      "read_orders",
      "read_products",
      "read_customers"
    ]
    |> Enum.join(", ")
  end

  # Registers webhooks for the shop
  defp register_webhooks(shop, access_token) do
    webhook_base_url =
      Application.get_env(:shopify_whatsapp, :webhook_base_url, get_default_webhook_url())

    # Register orders/create webhook
    case ShopifyWhatsapp.Shopify.API.create_webhook(
           shop.shop_domain,
           "orders/create",
           "#{webhook_base_url}/webhooks/shopify/orders/create",
           access_token
         ) do
      {:ok, webhook} ->
        webhook_id = get_in(webhook, ["webhook", "id"])
        update_webhook_id(shop, :orders_create_webhook_id, webhook_id)

      {:error, reason} ->
        Logger.warning("Failed to register orders/create webhook: #{inspect(reason)}")
    end

    # Register orders/updated webhook
    case ShopifyWhatsapp.Shopify.API.create_webhook(
           shop.shop_domain,
           "orders/updated",
           "#{webhook_base_url}/webhooks/shopify/orders/updated",
           access_token
         ) do
      {:ok, webhook} ->
        webhook_id = get_in(webhook, ["webhook", "id"])
        update_webhook_id(shop, :orders_updated_webhook_id, webhook_id)

      {:error, reason} ->
        Logger.warning("Failed to register orders/updated webhook: #{inspect(reason)}")
    end
  end

  defp update_webhook_id(shop, field, webhook_id) when is_binary(webhook_id) do
    shop
    |> ShopifyWhatsapp.Shop.webhooks_changeset(%{field => webhook_id})
    |> ShopifyWhatsapp.Repo.update()
  end

  defp update_webhook_id(_shop, _field, _webhook_id), do: :ok

  defp get_default_webhook_url do
    host = Application.get_env(:shopify_whatsapp, :app_host, "localhost:4000")
    scheme = if Application.get_env(:shopify_whatsapp, :https?), do: "https", else: "http"
    "#{scheme}://#{host}"
  end
end
