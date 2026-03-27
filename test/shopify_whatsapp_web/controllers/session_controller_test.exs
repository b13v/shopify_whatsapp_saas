defmodule ShopifyWhatsappWeb.SessionControllerTest do
  use ShopifyWhatsappWeb.ConnCase

  import ShopifyWhatsapp.TestFactory

  describe "DELETE /logout" do
    test "clears session and redirects to /", %{conn: conn} do
      shop = insert(:shop)

      conn =
        conn
        |> init_test_session(%{"shop_domain" => shop.shop_domain})
        |> delete(~p"/logout")

      assert redirected_to(conn) == "/"
      assert get_session(conn, "shop_domain") == nil
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "Logged out"
    end

    test "works even without a session", %{conn: conn} do
      conn = delete(conn, ~p"/logout")

      assert redirected_to(conn) == "/"
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "Logged out"
    end
  end
end
