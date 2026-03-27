defmodule ShopifyWhatsappWeb.LiveAuth do
  @moduledoc """
  on_mount authentication hook for LiveViews.
  Reads shop_domain from session and assigns current_shop to socket.
  """

  alias ShopifyWhatsapp.{Repo, Shop}
  alias Phoenix.LiveView.Utils

  def on_mount(:default, _params, session, socket) do
    shop_domain = session["shop_domain"]

    case shop_domain && Repo.get_by(Shop, shop_domain: shop_domain) do
      nil ->
        {:halt, Phoenix.LiveView.redirect(socket, to: "/")}

      shop ->
        {:cont, Utils.assign(socket, :current_shop, shop)}
    end
  end
end
