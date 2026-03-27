defmodule ShopifyWhatsappWeb.LiveAuth do
  @moduledoc """
  on_mount authentication hook for LiveViews.
  Reads shop_domain from session and assigns current_shop to socket.
  Sessions expire after a configurable TTL (default 7 days).
  """

  alias ShopifyWhatsapp.{Repo, Shop}
  alias Phoenix.LiveView.Utils

  @default_ttl_hours 168

  def on_mount(:default, _params, session, socket) do
    shop_domain = session["shop_domain"]

    if shop_domain && session_fresh?(session) do
      case Repo.get_by(Shop, shop_domain: shop_domain) do
        nil ->
          {:halt, Phoenix.LiveView.redirect(socket, to: "/")}

        shop ->
          {:cont, Utils.assign(socket, :current_shop, shop)}
      end
    else
      {:halt, Phoenix.LiveView.redirect(socket, to: "/")}
    end
  end

  defp session_fresh?(session) do
    ttl_hours = Application.get_env(:shopify_whatsapp, :session_ttl_hours, @default_ttl_hours)
    last_auth = session["last_auth_at"]

    case last_auth do
      nil -> true
      ts when is_binary(ts) ->
        case DateTime.from_iso8601(ts) do
          {:ok, last, _offset} ->
            hours_elapsed = DateTime.diff(DateTime.utc_now(), last, :hour)
            hours_elapsed < ttl_hours

          _ ->
            false
        end

      _ ->
        false
    end
  end
end
