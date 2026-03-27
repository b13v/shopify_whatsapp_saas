defmodule ShopifyWhatsappWeb.DevLoginController do
  @moduledoc """
  Dev-only controller that creates a test shop and session.
  Only available when dev_routes are enabled.
  """
  use ShopifyWhatsappWeb, :controller

  alias ShopifyWhatsapp.{Repo, Shop}

  @test_shop_domain "test-store.myshopify.com"

  def index(conn, _params) do
    shop =
      case Repo.get_by(Shop, shop_domain: @test_shop_domain) do
        nil ->
          {:ok, shop} =
            Shop.create_changeset(%{
              shop_domain: @test_shop_domain,
              plain_token: "dev_test_token"
            })
            |> Repo.insert()

          shop

        shop ->
          shop
      end

    conn
    |> put_session("shop_domain", shop.shop_domain)
    |> put_session("last_auth_at", DateTime.utc_now() |> DateTime.to_iso8601())
    |> put_flash(:info, "Logged in as #{shop.shop_domain} (dev mode)")
    |> redirect(to: "/dashboard")
  end
end
