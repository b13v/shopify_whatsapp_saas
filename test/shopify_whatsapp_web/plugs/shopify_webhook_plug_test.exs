defmodule ShopifyWhatsappWeb.ShopifyWebhookPlugTest do
  use ShopifyWhatsappWeb.ConnCase

  @secret "test_webhook_secret"

  setup do
    original = Application.get_env(:shopify_whatsapp, :shopify_webhook_secret)
    Application.put_env(:shopify_whatsapp, :shopify_webhook_secret, @secret)

    on_exit(fn ->
      Application.put_env(:shopify_whatsapp, :shopify_webhook_secret, original)
    end)

    :ok
  end

  defp compute_hmac(body) do
    :crypto.mac(:hmac, :sha256, @secret, body)
    |> Base.encode64()
  end

  # Simulates what CacheBodyReader does: reads the body and caches it
  # in conn.assigns[:raw_body] so the plug can access it after Plug.Parsers.
  defp with_cached_body(conn, body) do
    conn
    |> Plug.Conn.assign(:raw_body, body)
  end

  describe "call/2" do
    test "valid HMAC passes request through" do
      body = Jason.encode!(%{test: "data"})
      hmac = compute_hmac(body)

      conn =
        Plug.Test.conn(:post, "/webhooks/shopify/orders/create", body)
        |> put_req_header("x-shopify-hmac-sha256", hmac)
        |> with_cached_body(body)

      conn = ShopifyWhatsappWeb.ShopifyWebhookPlug.call(conn, [])

      refute conn.halted
    end

    test "invalid HMAC returns 401" do
      body = Jason.encode!(%{test: "data"})

      conn =
        Plug.Test.conn(:post, "/webhooks/shopify/orders/create", body)
        |> put_req_header("x-shopify-hmac-sha256", "invalid_hmac_signature")
        |> with_cached_body(body)

      conn = ShopifyWhatsappWeb.ShopifyWebhookPlug.call(conn, [])

      assert conn.status == 401
      assert conn.halted
      assert Jason.decode!(conn.resp_body) == %{"error" => "Unauthorized"}
    end

    test "missing HMAC header returns 401" do
      body = Jason.encode!(%{test: "data"})

      conn =
        Plug.Test.conn(:post, "/webhooks/shopify/orders/create", body)
        |> with_cached_body(body)

      conn = ShopifyWhatsappWeb.ShopifyWebhookPlug.call(conn, [])

      assert conn.status == 401
      assert conn.halted
      assert Jason.decode!(conn.resp_body) == %{"error" => "Unauthorized"}
    end
  end
end
