defmodule ShopifyWhatsapp.Telemetry do
  @moduledoc """
  Structured logging and telemetry for the application.

  Provides consistent logging for:
  - Shopify API errors
  - WhatsApp errors
  - Job failures
  - Business events
  """

  require Logger

  @type log_level :: :info | :warning | :error

  @doc """
  Logs a Shopify API error with context.
  """
  def log_shopify_error(function, reason, context \\ %{}) do
    log_error(:shopify_api, %{
      function: function,
      reason: inspect(reason),
      context: context
    })
  end

  @doc """
  Logs a WhatsApp API error with context.
  """
  def log_whatsapp_error(function, reason, context \\ %{}) do
    log_error(:whatsapp_api, %{
      function: function,
      reason: inspect(reason),
      context: context
    })
  end

  @doc """
  Logs a job failure with context.
  """
  def log_job_failure(worker, args, reason, context \\ %{}) do
    log_error(:job_failure, %{
      worker: worker,
      args: sanitize_args(args),
      reason: inspect(reason),
      context: context
    })
  end

  @doc """
  Logs a webhook event.
  """
  def log_webhook_received(shop_domain, topic, order_id) do
    log_info(:webhook_received, %{
      shop_domain: shop_domain,
      topic: topic,
      order_id: order_id
    })
  end

  @doc """
  Logs a webhook processing result.
  """
  def log_webhook_processed(shop_domain, topic, order_id, result) do
    log_info(:webhook_processed, %{
      shop_domain: shop_domain,
      topic: topic,
      order_id: order_id,
      result: result
    })
  end

  @doc """
  Logs a message sending event.
  """
  def log_message_sent(shop_id, order_id, message_type, status) do
    log_info(:message_sent, %{
      shop_id: shop_id,
      order_id: order_id,
      message_type: message_type,
      status: status
    })
  end

  # Private helpers

  defp log_error(event_type, metadata) do
    Logger.metadata([event_type: event_type] ++ Map.to_list(metadata))
    Logger.error("#{event_type}: #{inspect(metadata)}")
    Logger.reset_metadata()
  end

  defp log_info(event_type, metadata) do
    Logger.metadata([event_type: event_type] ++ Map.to_list(metadata))
    Logger.info("#{event_type}: #{inspect(metadata)}")
    Logger.reset_metadata()
  end

  # Sanitize args to remove sensitive data before logging
  defp sanitize_args(args) when is_map(args) do
    args
    |> Enum.map(fn {k, v} -> {k, sanitize_value(k, v)} end)
    |> Map.new()
  end

  defp sanitize_args(args), do: inspect(args)

  defp sanitize_value(key, value) when key in ["access_token", "plain_token", "token"] do
    "[REDACTED]"
  end

  defp sanitize_value(_key, value) when is_binary(value) do
    if String.length(value) > 100 do
      String.slice(value, 0..97) <> "..."
    else
      value
    end
  end

  defp sanitize_value(_key, value), do: value
end
