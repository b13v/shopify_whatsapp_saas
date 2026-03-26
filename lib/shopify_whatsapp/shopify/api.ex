defmodule ShopifyWhatsapp.Shopify.API do
  @moduledoc """
  Base Shopify API client using req HTTP client.

  Provides methods for interacting with Shopify Admin API for orders,
  shops, and webhook management.
  """

  @doc """
  Fetches a single order from Shopify.

  ## Parameters
    - shop_domain: The shop's myshopify.com domain
    - order_id: The Shopify order ID (integer or string)
    - access_token: The shop's OAuth access token

  ## Returns
    - `{:ok, order_map}` on success
    - `{:error, reason}` on failure
  """
  def get_order(shop_domain, order_id, access_token) do
    get(shop_domain, "/orders/#{order_id}.json", access_token)
  end

  @doc """
  Fetches shop information from Shopify.

  ## Parameters
    - shop_domain: The shop's myshopify.com domain
    - access_token: The shop's OAuth access token

  ## Returns
    - `{:ok, shop_map}` on success
    - `{:error, reason}` on failure
  """
  def get_shop(shop_domain, access_token) do
    get(shop_domain, "/shop.json", access_token)
  end

  @doc """
  Registers a webhook for the shop.

  ## Parameters
    - shop_domain: The shop's myshopify.com domain
    - topic: The webhook topic (e.g., "orders/create", "orders/updated")
    - address: The URL where Shopify will send webhook payloads
    - access_token: The shop's OAuth access token

  ## Returns
    - `{:ok, webhook_map}` on success
    - `{:error, reason}` on failure
  """
  def create_webhook(shop_domain, topic, address, access_token) do
    body = %{
      webhook: %{
        topic: topic,
        address: address,
        format: "json"
      }
    }

    post(shop_domain, "/webhooks.json", body, access_token)
  end

  @doc """
  Lists registered webhooks for the shop.

  ## Parameters
    - shop_domain: The shop's myshopify.com domain
    - access_token: The shop's OAuth access token

  ## Returns
    - `{:ok, [webhook_map, ...]}` on success
    - `{:error, reason}` on failure
  """
  def list_webhooks(shop_domain, access_token) do
    case get(shop_domain, "/webhooks.json", access_token) do
      {:ok, %{"webhooks" => webhooks}} -> {:ok, webhooks}
      {:ok, _} -> {:ok, []}
      error -> error
    end
  end

  @doc """
  Deletes a webhook.

  ## Parameters
    - shop_domain: The shop's myshopify.com domain
    - webhook_id: The webhook ID to delete
    - access_token: The shop's OAuth access token

  ## Returns
    - `:ok` on success
    - `{:error, reason}` on failure
  """
  def delete_webhook(shop_domain, webhook_id, access_token) do
    url = base_url(shop_domain) <> "/admin/api/2024-01/webhooks/#{webhook_id}.json"

    url
    |> Req.delete(
      auth: {:bearer, access_token},
      headers: [{"Content-Type", "application/json"}]
    )
    |> handle_response()
  end

  # Private helpers

  defp get(shop_domain, path, access_token) do
    url = base_url(shop_domain) <> admin_api_prefix() <> path

    url
    |> Req.get(auth: {:bearer, access_token})
    |> handle_response()
  end

  defp post(shop_domain, path, body, access_token) do
    url = base_url(shop_domain) <> admin_api_prefix() <> path

    url
    |> Req.post(
      auth: {:bearer, access_token},
      headers: [{"Content-Type", "application/json"}],
      body: Jason.encode!(body)
    )
    |> handle_response()
  end

  defp base_url(shop_domain) do
    # Ensure the domain has the proper format
    domain =
      cond do
        String.contains?(shop_domain, ".myshopify.com") -> shop_domain
        String.contains?(shop_domain, ".") -> shop_domain
        true -> shop_domain <> ".myshopify.com"
      end

    "https://" <> domain
  end

  defp admin_api_prefix, do: "/admin/api/2024-01"

  defp handle_response(resp) do
    case resp do
      {:ok, %{status: status} = response} when status in 200..299 ->
        {:ok, response.body}

      {:ok, %{status: status, body: body}} when status in 400..499 ->
        {:error, {:client_error, status, body}}

      {:ok, %{status: status, body: body}} when status in 500..599 ->
        {:error, {:server_error, status, body}}

      {:error, %Req.TransportError{reason: reason}} ->
        {:error, {:transport_error, reason}}

      {:error, reason} ->
        {:error, {:unknown_error, reason}}
    end
  end
end
