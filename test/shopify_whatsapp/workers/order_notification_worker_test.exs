defmodule ShopifyWhatsapp.OrderNotificationWorkerTest do
  use ShopifyWhatsapp.DataCase

  import ShopifyWhatsapp.TestFactory

  alias ShopifyWhatsapp.OrderNotificationWorker

  defp build_job(shop_domain, order, topic) do
    %Oban.Job{
      args: %{
        "shop_domain" => shop_domain,
        "order" => order,
        "topic" => topic
      },
      worker: OrderNotificationWorker,
      queue: :whatsapp
    }
  end

  describe "perform/1" do
    test "discards when shop not found" do
      job =
        build_job("nonexistent.myshopify.com", %{
          "order_id" => "1",
          "customer_phone" => "+15551234567"
        }, "orders_create")

      assert {:discard, :shop_not_found} = OrderNotificationWorker.perform(job)
    end

    test "returns ok when shop has no whatsapp_phone configured" do
      shop = insert(:shop, whatsapp_phone: nil)

      job =
        build_job(shop.shop_domain, %{
          "order_id" => "1",
          "customer_phone" => "+15551234567"
        }, "orders_create")

      assert :ok = OrderNotificationWorker.perform(job)
    end

    test "returns error for unknown topic" do
      shop = insert(:shop, whatsapp_phone: "+1234567890")

      job =
        build_job(shop.shop_domain, %{
          "order_id" => "1",
          "customer_phone" => "+15551234567"
        }, "unknown_topic")

      assert {:error, :unknown_topic} = OrderNotificationWorker.perform(job)
    end

    test "returns error when WhatsApp API call fails" do
      shop = insert(:shop, whatsapp_phone: "+1234567890")

      job =
        build_job(shop.shop_domain, %{
          "order_id" => "1",
          "customer_phone" => "+15551234567",
          "order_number" => "#1001",
          "customer_name" => "John"
        }, "orders_create")

      # WhatsApp API call will fail (no real server), creating a pending
      # message then failing on send. The worker returns {:error, reason}.
      result = OrderNotificationWorker.perform(job)
      assert match?({:error, _}, result)
    end
  end
end
