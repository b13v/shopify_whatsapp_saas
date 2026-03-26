defmodule ShopifyWhatsappWeb.DashboardLiveTest do
  use ShopifyWhatsappWeb.ConnCase

  import Phoenix.LiveViewTest
  import ShopifyWhatsapp.TestFactory

  describe "mount" do
    test "without shop param redirects to /", %{conn: conn} do
      {:error, {:redirect, %{to: "/"}}} = live(conn, "/dashboard")
    end

    test "with non-existent shop redirects to / with flash error", %{conn: conn} do
      {:error, {:redirect, %{to: "/"}}} = live(conn, "/dashboard?shop=nonexistent.myshopify.com")
    end

    test "with valid shop shows stats and messages", %{conn: conn} do
      shop = insert(:shop)

      {:ok, _view, html} = live(conn, "/dashboard?shop=#{shop.shop_domain}")

      assert html =~ "Dashboard"
      assert html =~ shop.shop_domain
      assert html =~ "Messages Sent"
      assert html =~ "Delivery Rate"
      assert html =~ "Failed"
      assert html =~ "Pending"
    end

    test "with valid shop shows zero stats initially", %{conn: conn} do
      shop = insert(:shop)

      {:ok, _view, html} = live(conn, "/dashboard?shop=#{shop.shop_domain}")

      assert html =~ ">0<"
      assert html =~ "No messages yet"
    end

    test "with messages shows them in the table", %{conn: conn} do
      shop = insert(:shop)
      insert(:sent_message, shop: shop, order_id: "1001", customer_phone: "+15551234567")

      {:ok, _view, html} = live(conn, "/dashboard?shop=#{shop.shop_domain}")

      assert html =~ "1001"
      assert html =~ "Sent"
    end
  end

  describe "filter_messages" do
    test "filters messages by status", %{conn: conn} do
      shop = insert(:shop)
      insert(:sent_message, shop: shop, order_id: "1001")
      insert(:failed_message, shop: shop, order_id: "1002")

      {:ok, view, _html} = live(conn, "/dashboard?shop=#{shop.shop_domain}")

      # Filter to failed only
      html = render_change(view, :filter_messages, %{"status" => "failed"})

      assert html =~ "1002"
      refute html =~ "1001"
    end

    test "all status shows all messages", %{conn: conn} do
      shop = insert(:shop)
      insert(:sent_message, shop: shop, order_id: "1001")
      insert(:failed_message, shop: shop, order_id: "1002")

      {:ok, view, _html} = live(conn, "/dashboard?shop=#{shop.shop_domain}")

      html = render_change(view, :filter_messages, %{"status" => "all"})

      assert html =~ "1001"
      assert html =~ "1002"
    end
  end
end
