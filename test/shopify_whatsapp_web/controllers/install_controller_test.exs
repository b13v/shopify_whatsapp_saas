defmodule ShopifyWhatsappWeb.InstallControllerTest do
  use ShopifyWhatsappWeb.ConnCase

  alias ShopifyWhatsapp.Shop

  describe "index/2" do
    test "valid shop domain redirects to Shopify OAuth" do
      conn = get(build_conn(), "/install", %{"shop" => "my-store.myshopify.com"})

      assert conn.status == 302
      assert redirected_to(conn) =~ "my-store.myshopify.com"
      assert redirected_to(conn) =~ "/admin/oauth/authorize"
    end

    test "invalid shop domain returns 400" do
      conn = get(build_conn(), "/install", %{"shop" => "not-a-valid-domain"})

      assert conn.status == 400
      assert conn.resp_body =~ "Invalid shop domain"
    end

    test "missing shop param returns error" do
      assert_raise Phoenix.ActionClauseError, fn ->
        get(build_conn(), "/install")
      end
    end

    test "domain with spaces returns 400" do
      conn = get(build_conn(), "/install", %{"shop" => "my store.myshopify.com"})

      assert conn.status == 400
    end
  end

  describe "callback/2" do
    test "missing required params returns 400" do
      conn = get(build_conn(), "/install/callback", %{})

      assert conn.status == 400
      assert conn.resp_body =~ "Bad Request"
    end

    test "valid HMAC but failed token exchange returns 500" do
      params = %{
        "shop" => "test-store.myshopify.com",
        "code" => "valid_code",
        "hmac" => compute_hmac(%{"code" => "valid_code", "shop" => "test-store.myshopify.com"})
      }

      # Token exchange will fail because Req can't reach shopify
      conn = get(build_conn(), "/install/callback", params)

      assert conn.status == 500
    end
  end

  # Helper to compute HMAC for install callback params
  defp compute_hmac(params) do
    params_without_hmac =
      params
      |> Enum.sort_by(fn {k, _v} -> k end)
      |> Enum.map(fn {k, v} -> "#{k}=#{v}" end)
      |> Enum.join("&")

    :crypto.mac(:hmac, :sha256, "test_api_secret", params_without_hmac)
    |> Base.encode16(case: :lower)
  end
end
