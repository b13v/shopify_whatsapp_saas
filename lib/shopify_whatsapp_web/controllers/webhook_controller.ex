defmodule ShopifyWhatsappWeb.WebhookController do
  use ShopifyWhatsappWeb, :controller

  require Logger
  import Ecto.Query

  alias ShopifyWhatsapp.Repo
  alias ShopifyWhatsapp.Shop
  alias ShopifyWhatsapp.Message

  plug ShopifyWhatsappWeb.ShopifyWebhookPlug

  @doc """
  Handles orders/create webhook from Shopify.

  Queues an order notification job to send a WhatsApp message to the customer.
  Idempotent: skips if order was already processed.
  """
  def orders_create(conn, params) do
    # Extract shop domain from headers
    shop_domain = get_shop_domain(conn)

    ShopifyWhatsapp.Telemetry.log_webhook_received(
      shop_domain,
      "orders/create",
      params["id"]
    )

    # Extract order data
    case extract_order_data(params) do
      {:ok, order_data} ->
        # Check idempotency - skip if already processed
        if order_already_processed?(shop_domain, order_data["order_id"], "order_confirmation") do
          Logger.info("Order #{order_data["order_id"]} already processed, skipping")
          send_resp(conn, 200, "")
        else
          # Queue the notification job
          %{shop_domain: shop_domain, order: order_data, topic: :orders_create}
          |> Oban.Job.new(worker: ShopifyWhatsapp.OrderNotificationWorker, queue: :whatsapp)
          |> Oban.insert()

          send_resp(conn, 200, "")
        end

      {:error, :invalid_order} ->
        Logger.warning("Invalid order data in webhook: #{inspect(params)}")
        send_resp(conn, 422, Jason.encode!(%{error: "Invalid order data"}))
    end
  end

  @doc """
  Handles orders/updated webhook from Shopify.

  Queues an order update notification job.
  Idempotent: skips if order was already processed for this status.
  """
  def orders_updated(conn, params) do
    shop_domain = get_shop_domain(conn)

    ShopifyWhatsapp.Telemetry.log_webhook_received(
      shop_domain,
      "orders_updated",
      params["id"]
    )

    case extract_order_data(params) do
      {:ok, order_data} ->
        # Check idempotency - skip if already processed with same status
        # For updates, we do want to allow re-processing if status changed significantly
        # but to avoid spam, we check recent messages
        if recently_processed?(shop_domain, order_data["order_id"], "order_update") do
          Logger.info("Order #{order_data["order_id"]} recently processed, skipping")
          send_resp(conn, 200, "")
        else
          # Queue the notification job
          %{shop_domain: shop_domain, order: order_data, topic: :orders_updated}
          |> Oban.Job.new(worker: ShopifyWhatsapp.OrderNotificationWorker, queue: :whatsapp)
          |> Oban.insert()

          send_resp(conn, 200, "")
        end

      {:error, :invalid_order} ->
        Logger.warning("Invalid order data in webhook: #{inspect(params)}")
        send_resp(conn, 422, Jason.encode!(%{error: "Invalid order data"}))
    end
  end

  # Private helpers

  defp get_shop_domain(conn) do
    case get_req_header(conn, "x-shopify-shop-domain") do
      [domain] -> domain
      [] -> raise "Missing X-Shopify-Shop-Domain header"
    end
  end

  # Check if an order was already processed for a given message type
  defp order_already_processed?(shop_domain, order_id, message_type) do
    case Repo.get_by(Shop, shop_domain: shop_domain) do
      nil ->
        false

      shop ->
        Repo.exists?(
          from m in Message,
            where: m.shop_id == ^shop.id,
            where: m.order_id == ^order_id,
            where: m.message_type == ^message_type,
            where: m.status in ["sent", "delivered"]
        )
    end
  end

  # Check if an order was processed in the last hour (avoid duplicate updates)
  defp recently_processed?(shop_domain, order_id, message_type) do
    case Repo.get_by(Shop, shop_domain: shop_domain) do
      nil ->
        false

      shop ->
        one_hour_ago = DateTime.utc_now() |> DateTime.add(-3600)

        Repo.exists?(
          from m in Message,
            where: m.shop_id == ^shop.id,
            where: m.order_id == ^order_id,
            where: m.message_type == ^message_type,
            where: m.inserted_at > ^one_hour_ago
        )
    end
  end

  defp extract_order_data(%{"id" => order_id} = params) when is_binary(order_id) do
    # Extract order ID (Shopify sends it as gid://shopify/Order/12345)
    numeric_id =
      order_id
      |> String.split("/")
      |> List.last()

    customer_phone = get_in(params, ["customer", "phone"])

    # Verify required fields
    if is_nil(customer_phone) or customer_phone == "" do
      {:error, :invalid_order}
    else
      order_data = %{
        "order_id" => numeric_id,
        "order_gid" => order_id,
        "order_number" => Map.get(params, "name"),
        "customer_phone" => normalize_phone(customer_phone),
        "customer_name" => get_in(params, ["customer", "first_name"]),
        "financial_status" => Map.get(params, "financial_status"),
        "fulfillment_status" => Map.get(params, "fulfillment_status"),
        "tags" => Map.get(params, "tags", "")
      }

      {:ok, order_data}
    end
  end

  defp extract_order_data(_), do: {:error, :invalid_order}

  # Normalize phone number to E.164 format
  defp normalize_phone(phone) when is_binary(phone) do
    phone
    |> String.trim()
    |> String.replace(~r/[^0-9+]/, "")
    |> then(fn
      "" -> nil
      "+" <> _rest -> phone
      cleaned -> "+#{cleaned}"
    end)
  end
end
