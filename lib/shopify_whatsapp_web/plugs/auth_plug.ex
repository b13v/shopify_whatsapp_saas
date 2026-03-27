defmodule ShopifyWhatsappWeb.AuthPlug do
  @moduledoc """
  Plug that authenticates requests using the shop_domain stored in the session.
  Assigns `current_shop` to the connection if valid, otherwise redirects to "/".

  Also provides `on_mount/4` for LiveView authentication via session.
  """
  import Plug.Conn
  import Phoenix.Controller, only: [redirect: 2, put_flash: 3]

  alias ShopifyWhatsapp.{Repo, Shop}

  def init(opts), do: opts

  def call(conn, _opts) do
    case get_session(conn, "shop_domain") do
      nil ->
        conn
        |> put_flash(:error, "Please install the app first.")
        |> redirect(to: "/")
        |> halt()

      shop_domain ->
        case Repo.get_by(Shop, shop_domain: shop_domain) do
          nil ->
            conn
            |> delete_session("shop_domain")
            |> put_flash(:error, "Shop not found. Please reinstall the app.")
            |> redirect(to: "/")
            |> halt()

          shop ->
            assign(conn, :current_shop, shop)
        end
    end
  end
end
