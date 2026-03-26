defmodule ShopifyWhatsapp.Dashboard do
  @moduledoc """
  Context for dashboard queries and statistics.
  """

  import Ecto.Query

  alias ShopifyWhatsapp.Message
  alias ShopifyWhatsapp.Repo
  alias ShopifyWhatsapp.Shop

  @doc """
  Get message statistics for a shop.

  Returns a map with:
  - sent: total messages sent
  - delivered: total messages delivered
  - failed: total messages failed
  - pending: total messages pending
  - delivery_rate: percentage of delivered vs sent
  """
  def message_stats(shop_id) do
    base_query =
      from m in Message,
        where: m.shop_id == ^shop_id

    sent =
      base_query
      |> where([m], m.status in ["sent", "delivered"])
      |> Repo.aggregate(:count)

    delivered =
      base_query
      |> where([m], m.status == "delivered")
      |> Repo.aggregate(:count)

    failed =
      base_query
      |> where([m], m.status == "failed")
      |> Repo.aggregate(:count)

    pending =
      base_query
      |> where([m], m.status == "pending")
      |> Repo.aggregate(:count)

    delivery_rate =
      if sent > 0 do
        Float.round(delivered / sent * 100, 1)
      else
        0.0
      end

    %{
      sent: sent,
      delivered: delivered,
      failed: failed,
      pending: pending,
      delivery_rate: delivery_rate
    }
  end

  @doc """
  Get recent messages for a shop.

  Options:
  - limit: number of messages to return (default: 50)
  - status: filter by status (optional)
  """
  def recent_messages(shop_id, opts \\ []) do
    limit = Keyword.get(opts, :limit, 50)
    status_filter = Keyword.get(opts, :status)

    query =
      from m in Message,
        where: m.shop_id == ^shop_id,
        order_by: [desc: m.inserted_at],
        limit: ^limit

    query =
      if status_filter do
        where(query, [m], m.status == ^status_filter)
      else
        query
      end

    Repo.all(query)
  end

  @doc """
  Get daily message counts for the last 30 days.
  """
  def daily_counts(shop_id, days \\ 30) do
    start_date = DateTime.utc_now() |> DateTime.add(-days * 24 * 60 * 60)

    query =
      from m in Message,
        where: m.shop_id == ^shop_id,
        where: m.inserted_at >= ^start_date,
        group_by: fragment("DATE(?)", m.inserted_at),
        order_by: [desc: fragment("date")],
        select: %{
          date: fragment("DATE(?)", m.inserted_at),
          sent: count(filter(m.status in ^["sent", "delivered"])),
          delivered: count(filter(m.status == ^"delivered")),
          failed: count(filter(m.status == ^"failed"))
        }

    Repo.all(query)
  end

  @doc """
  Get shop by domain.
  """
  def get_shop_by_domain(domain) do
    normalized_domain = Shop.normalize_domain(domain)
    Repo.get_by(Shop, shop_domain: normalized_domain)
  end
end
