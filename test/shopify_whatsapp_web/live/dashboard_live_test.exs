defmodule ShopifyWhatsappWeb.DashboardLiveTest do
  use ShopifyWhatsappWeb.ConnCase

  import Phoenix.LiveViewTest
  import ShopifyWhatsapp.TestFactory

  describe "mount" do
    test "without session redirects to /", %{conn: conn} do
      {:error, {:redirect, %{to: "/"}}} = live(conn, "/dashboard")
    end

    test "with non-existent shop in session redirects to /", %{conn: conn} do
      {:error, {:redirect, %{to: "/"}}} =
        conn
        |> init_test_session(%{"shop_domain" => "nonexistent.myshopify.com"})
        |> live("/dashboard")
    end

    test "with valid session shows stats and messages", %{conn: conn} do
      shop = insert(:shop)

      {:ok, _view, html} =
        conn
        |> init_test_session(%{"shop_domain" => shop.shop_domain})
        |> live("/dashboard")

      assert html =~ "Messages Sent"
      assert html =~ "Delivery Rate"
      assert html =~ "Failed"
      assert html =~ "Pending"
    end

    test "with valid session shows zero stats initially", %{conn: conn} do
      shop = insert(:shop)

      {:ok, _view, html} =
        conn
        |> init_test_session(%{"shop_domain" => shop.shop_domain})
        |> live("/dashboard")

      assert html =~ ">0<"
      assert html =~ "No messages yet"
    end

    test "with messages shows them in the table", %{conn: conn} do
      shop = insert(:shop)
      insert(:sent_message, shop: shop, order_id: "1001", customer_phone: "+15551234567")

      {:ok, _view, html} =
        conn
        |> init_test_session(%{"shop_domain" => shop.shop_domain})
        |> live("/dashboard")

      assert html =~ "1001"
      assert html =~ "Sent"
    end

    test "shows shop domain in header", %{conn: conn} do
      shop = insert(:shop)

      {:ok, _view, html} =
        conn
        |> init_test_session(%{"shop_domain" => shop.shop_domain})
        |> live("/dashboard")

      assert html =~ shop.shop_domain
    end

    test "shows navigation tabs", %{conn: conn} do
      shop = insert(:shop)

      {:ok, _view, html} =
        conn
        |> init_test_session(%{"shop_domain" => shop.shop_domain})
        |> live("/dashboard")

      assert html =~ ~s{href="/dashboard"}
      assert html =~ ~s{href="/dashboard/settings"}
      assert html =~ "Settings"
    end

    test "shows logout link", %{conn: conn} do
      shop = insert(:shop)

      {:ok, _view, html} =
        conn
        |> init_test_session(%{"shop_domain" => shop.shop_domain})
        |> live("/dashboard")

      assert html =~ "Logout"
      assert html =~ ~s{href="/logout"}
    end
  end

  describe "filter_messages" do
    test "filters messages by status", %{conn: conn} do
      shop = insert(:shop)
      insert(:sent_message, shop: shop, order_id: "1001")
      insert(:failed_message, shop: shop, order_id: "1002")

      {:ok, view, _html} =
        conn
        |> init_test_session(%{"shop_domain" => shop.shop_domain})
        |> live("/dashboard")

      html = render_change(view, :filter_messages, %{"status" => "failed"})

      assert html =~ "1002"
      refute html =~ "1001"
    end

    test "all status shows all messages", %{conn: conn} do
      shop = insert(:shop)
      insert(:sent_message, shop: shop, order_id: "1001")
      insert(:failed_message, shop: shop, order_id: "1002")

      {:ok, view, _html} =
        conn
        |> init_test_session(%{"shop_domain" => shop.shop_domain})
        |> live("/dashboard")

      html = render_change(view, :filter_messages, %{"status" => "all"})

      assert html =~ "1001"
      assert html =~ "1002"
    end
  end
end
