defmodule ShopifyWhatsappWeb.SessionController do
  use ShopifyWhatsappWeb, :controller

  def delete(conn, _params) do
    conn
    |> delete_session("shop_domain")
    |> put_flash(:info, "Logged out successfully.")
    |> redirect(to: "/")
  end
end
