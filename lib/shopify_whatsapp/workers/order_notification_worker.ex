defmodule ShopifyWhatsapp.OrderNotificationWorker do
  @moduledoc """
  Oban worker for sending WhatsApp order notifications.

  Processes order events from Shopify webhooks and sends appropriate
  WhatsApp messages to customers.
  """

  use Oban.Worker,
    queue: :whatsapp,
    max_attempts: 3,
    priority: 1

  require Logger

  alias ShopifyWhatsapp.Shop
  alias ShopifyWhatsapp.Message
  alias ShopifyWhatsapp.Repo
  alias ShopifyWhatsapp.Whatsapp.Client

  @impl true
  def perform(%Oban.Job{args: %{"shop_domain" => shop_domain, "order" => order, "topic" => topic}}) do
    Logger.info("Processing order notification for shop: #{shop_domain}, topic: #{topic}")

    with {:ok, shop} <- get_shop(shop_domain),
         {:ok, phone} <- get_whatsapp_phone(shop),
         {:ok, message_type} <- get_message_type(topic),
         {:ok, template} <- get_template(message_type),
         {:ok, _message} <- create_and_send_message(shop, order, phone, template, message_type) do
      :ok
    else
      {:error, {:shop_not_found, _}} ->
        # Shop not installed - this is a permanent error
        Logger.warning("Shop not found: #{shop_domain}")
        {:discard, :shop_not_found}

      {:error, {:no_whatsapp_phone, _}} ->
        # Shop hasn't configured WhatsApp phone - skip silently
        Logger.info("Shop #{shop_domain} has no WhatsApp phone configured")
        :ok

      {:error, reason} ->
        # Retryable error
        Logger.error("Failed to send notification: #{inspect(reason)}")
        {:error, reason}
    end
  end

  # Private helpers

  defp get_shop(shop_domain) do
    case Repo.get_by(Shop, shop_domain: shop_domain) do
      nil -> {:error, {:shop_not_found, shop_domain}}
      shop -> {:ok, shop}
    end
  end

  defp get_whatsapp_phone(%Shop{whatsapp_phone: nil}) do
    {:error, {:no_whatsapp_phone, "not configured"}}
  end

  defp get_whatsapp_phone(%Shop{whatsapp_phone: phone}) when is_binary(phone) do
    {:ok, phone}
  end

  defp get_message_type(:orders_create), do: {:ok, :order_confirmation}
  defp get_message_type(:orders_updated), do: {:ok, :order_update}
  defp get_message_type(_), do: {:error, :unknown_topic}

  defp get_template(:order_confirmation) do
    {:ok,
     %{
       name: "order_confirmation",
       language_code: "en"
     }}
  end

  defp get_template(:order_update) do
    {:ok,
     %{
       name: "order_update",
       language_code: "en"
     }}
  end

  defp get_template(_), do: {:error, :unknown_template}

  defp create_and_send_message(shop, order, from_phone, template, message_type) do
    Ecto.Multi.new()
    |> Ecto.Multi.insert(
      :message,
      Message.create_changeset(%{
        shop_id: shop.id,
        order_id: order["order_id"],
        customer_phone: order["customer_phone"],
        message_type: Atom.to_string(message_type),
        status: "pending"
      })
    )
    |> Ecto.Multi.run(:send_notification, fn _, %{message: message} ->
      send_whatsapp_message(shop, order, from_phone, template, message)
    end)
    |> Ecto.Multi.update(:update_status, fn %{
                                              send_notification: {:ok, whatsapp_id},
                                              message: message
                                            } ->
      Message.mark_sent(message, whatsapp_id)
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{message: message}} ->
        {:ok, message}

      {:error, :send_notification, {:error, reason}, _} ->
        # Update message with error
        {:error, reason}
    end
  end

  defp send_whatsapp_message(_shop, order, from_phone, template, _message) do
    # Build template parameters
    template_params = build_template_params(order)

    # Send via WhatsApp client
    case Client.send_message(
           order["customer_phone"],
           template.name,
           template_params,
           phone_id: from_phone,
           language_code: template.language_code
         ) do
      {:ok, response} ->
        # Extract message ID from response
        whatsapp_id = get_in(response, ["messages", Access.at(0), "id"])
        {:ok, whatsapp_id || "sent"}

      {:error, {:rate_limited, retry_after: seconds}} when is_integer(seconds) ->
        # Schedule retry with backoff
        {:error, {:rate_limited, seconds}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp build_template_params(order) do
    %{
      "order_number" => Map.get(order, "order_number", "N/A"),
      "customer_name" => Map.get(order, "customer_name", "Customer")
    }
  end
end
