defmodule ShopifyWhatsapp.TestFactory do
  @moduledoc """
  ExMachina factories for test data.
  """

  use ExMachina.Ecto, repo: ShopifyWhatsapp.Repo

  alias ShopifyWhatsapp.{Message, Shop}

  def shop_factory do
    %Shop{
      shop_domain: sequence(:shop_domain, &"test-store-#{&1}.myshopify.com"),
      access_token: ShopifyWhatsapp.Vault.encrypt!("shpat_test_token"),
      whatsapp_phone: "+1234567890",
      installed_at: DateTime.utc_now() |> DateTime.truncate(:second)
    }
  end

  def message_factory do
    %Message{
      shop: build(:shop),
      order_id: sequence(:order_id, &"#{5_500_000_000 + &1}"),
      customer_phone: "+15551234567",
      message_type: "order_confirmation",
      status: "pending",
      retry_count: 0
    }
  end

  def sent_message_factory do
    struct!(
      build(:message),
      status: "sent",
      sent_at: DateTime.utc_now() |> DateTime.truncate(:second),
      whatsapp_message_id: "wamid_test_123"
    )
  end

  def delivered_message_factory do
    struct!(
      build(:sent_message),
      status: "delivered",
      delivered_at: DateTime.utc_now() |> DateTime.truncate(:second)
    )
  end

  def failed_message_factory do
    struct!(
      build(:message),
      status: "failed",
      error_reason: "API timeout"
    )
  end
end
