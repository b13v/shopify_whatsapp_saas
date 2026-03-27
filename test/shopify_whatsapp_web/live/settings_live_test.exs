defmodule ShopifyWhatsappWeb.SettingsLiveTest do
  use ShopifyWhatsappWeb.ConnCase

  import Phoenix.LiveViewTest
  import ShopifyWhatsapp.TestFactory

  describe "mount" do
    test "without session redirects to /", %{conn: conn} do
      {:error, {:redirect, %{to: "/"}}} = live(conn, "/dashboard/settings")
    end

    test "with valid session shows settings form", %{conn: conn} do
      shop = insert(:shop)

      {:ok, _view, html} =
        conn
        |> init_test_session(%{"shop_domain" => shop.shop_domain})
        |> live("/dashboard/settings")

      assert html =~ "WhatsApp Configuration"
      assert html =~ shop.shop_domain
      assert html =~ "WhatsApp Phone Number"
    end

    test "with non-existent shop in session redirects to /", %{conn: conn} do
      {:error, {:redirect, %{to: "/"}}} =
        conn
        |> init_test_session(%{"shop_domain" => "nonexistent.myshopify.com"})
        |> live("/dashboard/settings")
    end

    test "shows current whatsapp phone in form", %{conn: conn} do
      shop = insert(:shop, whatsapp_phone: "+1234567890")

      {:ok, _view, html} =
        conn
        |> init_test_session(%{"shop_domain" => shop.shop_domain})
        |> live("/dashboard/settings")

      assert html =~ "+1234567890"
    end

    test "shows webhook status badges", %{conn: conn} do
      shop =
        insert(:shop,
          orders_create_webhook_id: "123456",
          orders_updated_webhook_id: nil
        )

      {:ok, _view, html} =
        conn
        |> init_test_session(%{"shop_domain" => shop.shop_domain})
        |> live("/dashboard/settings")

      assert html =~ "Registered"
      assert html =~ "Not registered"
    end

    test "shows shop installation date", %{conn: conn} do
      shop = insert(:shop, installed_at: ~U[2026-01-15 10:30:00Z])

      {:ok, _view, html} =
        conn
        |> init_test_session(%{"shop_domain" => shop.shop_domain})
        |> live("/dashboard/settings")

      assert html =~ "2026-01-15"
    end
  end

  describe "save settings" do
    test "saves whatsapp phone number and shows success banner", %{conn: conn} do
      shop = insert(:shop, whatsapp_phone: nil)

      {:ok, view, _html} =
        conn
        |> init_test_session(%{"shop_domain" => shop.shop_domain})
        |> live("/dashboard/settings")

      html =
        view
        |> form("#settings-form", shop: %{whatsapp_phone: "+9876543210"})
        |> render_submit()

      assert html =~ "You&#39;re all set!"
      assert html =~ "+9876543210"
    end

    test "validates phone input on change", %{conn: conn} do
      shop = insert(:shop, whatsapp_phone: nil)

      {:ok, view, _html} =
        conn
        |> init_test_session(%{"shop_domain" => shop.shop_domain})
        |> live("/dashboard/settings")

      html =
        render_change(view, :validate, %{shop: %{whatsapp_phone: "+9876543210"}})

      assert html =~ "+9876543210"
    end
  end

  describe "navigation" do
    test "shows navigation link to dashboard", %{conn: conn} do
      shop = insert(:shop)

      {:ok, _view, html} =
        conn
        |> init_test_session(%{"shop_domain" => shop.shop_domain})
        |> live("/dashboard/settings")

      assert html =~ ~s{href="/dashboard"}
      assert html =~ "Dashboard"
    end

    test "settings tab is active", %{conn: conn} do
      shop = insert(:shop)

      {:ok, _view, html} =
        conn
        |> init_test_session(%{"shop_domain" => shop.shop_domain})
        |> live("/dashboard/settings")

      assert html =~ "border-green-500 text-green-700"
      assert html =~ "Settings"
    end

    test "shows logout link", %{conn: conn} do
      shop = insert(:shop)

      {:ok, _view, html} =
        conn
        |> init_test_session(%{"shop_domain" => shop.shop_domain})
        |> live("/dashboard/settings")

      assert html =~ "Logout"
      assert html =~ ~s{href="/logout"}
    end
  end

  describe "a11y" do
    test "renders main landmark", %{conn: conn} do
      shop = insert(:shop)

      {:ok, _view, html} =
        conn
        |> init_test_session(%{"shop_domain" => shop.shop_domain})
        |> live("/dashboard/settings")

      assert html =~ ~s{id="main-content"}
    end

    test "renders skip to content link", %{conn: conn} do
      shop = insert(:shop)

      {:ok, _view, html} =
        conn
        |> init_test_session(%{"shop_domain" => shop.shop_domain})
        |> live("/dashboard/settings")

      assert html =~ "Skip to content"
    end
  end
end
