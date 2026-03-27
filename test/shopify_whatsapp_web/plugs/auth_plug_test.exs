defmodule ShopifyWhatsappWeb.AuthPlugTest do
  use ShopifyWhatsappWeb.ConnCase

  import ShopifyWhatsapp.TestFactory
  alias ShopifyWhatsappWeb.AuthPlug

  setup %{conn: conn} do
    # init_test_session sets up session store, fetch_flash enables flash support
    conn =
      conn
      |> init_test_session(%{})
      |> fetch_flash()

    {:ok, conn: conn}
  end

  describe "call/2" do
    test "redirects to / when no session exists", %{conn: conn} do
      conn = AuthPlug.call(conn, [])

      assert redirected_to(conn) == "/"
      assert conn.assigns.flash["error"] =~ "install"
    end

    test "assigns current_shop when valid session exists", %{conn: conn} do
      shop = insert(:shop)

      conn =
        conn
        |> init_test_session(%{"shop_domain" => shop.shop_domain})
        |> fetch_flash()
        |> AuthPlug.call([])

      assert conn.assigns.current_shop.id == shop.id
      assert conn.assigns.current_shop.shop_domain == shop.shop_domain
    end

    test "clears session and redirects when shop no longer exists", %{conn: conn} do
      conn =
        conn
        |> init_test_session(%{"shop_domain" => "deleted-shop.myshopify.com"})
        |> fetch_flash()
        |> AuthPlug.call([])

      assert redirected_to(conn) == "/"
      assert get_session(conn, "shop_domain") == nil
      assert conn.assigns.flash["error"] =~ "not found"
    end
  end
end
