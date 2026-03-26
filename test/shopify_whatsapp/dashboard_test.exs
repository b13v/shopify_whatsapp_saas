defmodule ShopifyWhatsapp.DashboardTest do
  use ShopifyWhatsapp.DataCase

  import ShopifyWhatsapp.TestFactory

  alias ShopifyWhatsapp.Dashboard

  describe "message_stats/1" do
    test "returns zero counts for shop with no messages" do
      shop = insert(:shop)

      stats = Dashboard.message_stats(shop.id)

      assert stats == %{sent: 0, delivered: 0, failed: 0, pending: 0, delivery_rate: 0.0}
    end

    test "counts pending messages" do
      shop = insert(:shop)
      insert(:message, shop: shop, status: "pending")
      insert(:message, shop: shop, status: "pending")

      stats = Dashboard.message_stats(shop.id)

      assert stats.pending == 2
    end

    test "counts sent messages (sent + delivered)" do
      shop = insert(:shop)
      insert(:sent_message, shop: shop)
      insert(:delivered_message, shop: shop)

      stats = Dashboard.message_stats(shop.id)

      assert stats.sent == 2
    end

    test "counts delivered messages" do
      shop = insert(:shop)
      insert(:delivered_message, shop: shop)
      insert(:sent_message, shop: shop)

      stats = Dashboard.message_stats(shop.id)

      assert stats.delivered == 1
    end

    test "counts failed messages" do
      shop = insert(:shop)
      insert(:failed_message, shop: shop)
      insert(:failed_message, shop: shop)
      insert(:message, shop: shop)

      stats = Dashboard.message_stats(shop.id)

      assert stats.failed == 2
    end

    test "calculates delivery_rate correctly" do
      shop = insert(:shop)
      insert(:delivered_message, shop: shop)
      insert(:sent_message, shop: shop) # sent but not delivered
      insert(:failed_message, shop: shop)

      stats = Dashboard.message_stats(shop.id)

      # sent = 2 (1 delivered + 1 sent), delivered = 1
      assert stats.sent == 2
      assert stats.delivery_rate == 50.0
    end

    test "returns 0.0 delivery_rate when no sent messages" do
      shop = insert(:shop)
      insert(:message, shop: shop, status: "pending")

      stats = Dashboard.message_stats(shop.id)

      assert stats.delivery_rate == 0.0
    end

    test "does not count messages from other shops" do
      shop1 = insert(:shop)
      shop2 = insert(:shop)
      insert(:sent_message, shop: shop1)
      insert(:delivered_message, shop: shop2)

      stats = Dashboard.message_stats(shop1.id)

      assert stats.sent == 1
      assert stats.delivered == 0
    end
  end

  describe "recent_messages/2" do
    test "returns messages ordered by inserted_at desc" do
      shop = insert(:shop)
      now = DateTime.utc_now() |> DateTime.truncate(:second)

      msg1 =
        insert(:message,
          shop: shop,
          order_id: "1001",
          inserted_at: now,
          updated_at: now
        )

      msg2 =
        insert(:message,
          shop: shop,
          order_id: "1002",
          inserted_at: DateTime.add(now, 1, :second),
          updated_at: DateTime.add(now, 1, :second)
        )

      messages = Dashboard.recent_messages(shop.id)

      assert length(messages) == 2
      assert hd(messages).id == msg2.id
      assert List.last(messages).id == msg1.id
    end

    test "respects limit option" do
      shop = insert(:shop)
      insert(:message, shop: shop)
      insert(:message, shop: shop)
      insert(:message, shop: shop)

      messages = Dashboard.recent_messages(shop.id, limit: 2)

      assert length(messages) == 2
    end

    test "filters by status" do
      shop = insert(:shop)
      insert(:sent_message, shop: shop)
      insert(:failed_message, shop: shop)
      insert(:message, shop: shop, status: "pending")

      messages = Dashboard.recent_messages(shop.id, status: "failed")

      assert length(messages) == 1
      assert hd(messages).status == "failed"
    end

    test "returns empty list for shop with no messages" do
      shop = insert(:shop)

      messages = Dashboard.recent_messages(shop.id)

      assert messages == []
    end
  end

  describe "daily_counts/2" do
    test "returns daily counts within date range" do
      shop = insert(:shop)
      insert(:sent_message, shop: shop)

      counts = Dashboard.daily_counts(shop.id, 30)

      assert is_list(counts)
    end

    test "returns empty list for shop with no messages" do
      shop = insert(:shop)

      counts = Dashboard.daily_counts(shop.id, 30)

      assert counts == []
    end
  end

  describe "get_shop_by_domain/1" do
    test "finds shop by normalized domain" do
      shop = insert(:shop)

      found = Dashboard.get_shop_by_domain(shop.shop_domain)

      assert found.id == shop.id
    end

    test "normalizes domain before lookup" do
      shop = insert(:shop, shop_domain: "my-store.myshopify.com")

      found = Dashboard.get_shop_by_domain("https://my-store.myshopify.com/")

      assert found.id == shop.id
    end

    test "returns nil for non-existent shop" do
      assert Dashboard.get_shop_by_domain("nonexistent.myshopify.com") == nil
    end
  end
end
