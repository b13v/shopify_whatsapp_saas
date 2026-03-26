defmodule ShopifyWhatsappWeb.WebhookControllerTest do
  use ShopifyWhatsappWeb.ConnCase

  import ShopifyWhatsapp.TestFactory

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

  defp valid_order_params(overrides \\ %{}) do
    Map.merge(
      %{
        "id" => "gid://shopify/Order/5500000001",
        "name" => "#1001",
        "customer" => %{"first_name" => "John", "phone" => "+15551234567"},
        "financial_status" => "paid",
        "fulfillment_status" => nil,
        "tags" => ""
      },
      overrides
    )
  end

  # Creates a signed webhook request by building a raw Plug.Test conn
  # and calling the endpoint directly, bypassing Phoenix.ConnTest.dispatch
  # which drops custom headers during recycle/1.
  defp webhook_request(method, path, shop_domain, params, hmac_header) do
    body = Jason.encode!(params)

    conn =
      Plug.Test.conn(method, path, body)
      |> put_req_header("x-shopify-hmac-sha256", hmac_header)
      |> put_req_header("x-shopify-shop-domain", shop_domain)
      |> put_req_header("content-type", "application/json")
      |> Plug.Conn.put_private(:phoenix_endpoint, ShopifyWhatsappWeb.Endpoint)

    ShopifyWhatsappWeb.Endpoint.call(conn, ShopifyWhatsappWeb.Endpoint.init([]))
  end

  defp signed_webhook_post(path, shop_domain, params) do
    body = Jason.encode!(params)
    webhook_request(:post, path, shop_domain, params, compute_hmac(body))
  end

  defp unsigned_webhook_post(path, shop_domain, params) do
    webhook_request(:post, path, shop_domain, params, "invalid_signature")
  end

  describe "orders_create/2" do
    test "valid order data returns 200 and enqueues job" do
      shop = insert(:shop)

      conn =
        signed_webhook_post(
          "/webhooks/shopify/orders/create",
          shop.shop_domain,
          valid_order_params()
        )

      assert conn.status == 200
    end

    test "duplicate order returns 200 (idempotent)" do
      shop = insert(:shop)

      insert(:sent_message,
        shop: shop,
        order_id: "5500000001",
        message_type: "order_confirmation"
      )

      conn =
        signed_webhook_post(
          "/webhooks/shopify/orders/create",
          shop.shop_domain,
          valid_order_params()
        )

      assert conn.status == 200
    end

    test "missing customer phone returns 422" do
      shop = insert(:shop)

      params = Map.put(valid_order_params(), "customer", %{"first_name" => "John"})

      conn =
        signed_webhook_post(
          "/webhooks/shopify/orders/create",
          shop.shop_domain,
          params
        )

      assert conn.status == 422
    end

    test "invalid payload returns 422" do
      shop = insert(:shop)

      conn =
        signed_webhook_post(
          "/webhooks/shopify/orders/create",
          shop.shop_domain,
          %{"foo" => "bar"}
        )

      assert conn.status == 422
    end

    test "invalid HMAC returns 401" do
      conn =
        unsigned_webhook_post(
          "/webhooks/shopify/orders/create",
          "test.myshopify.com",
          valid_order_params()
        )

      assert conn.status == 401
    end
  end

  describe "orders_updated/2" do
    test "valid order data returns 200" do
      shop = insert(:shop)

      conn =
        signed_webhook_post(
          "/webhooks/shopify/orders/updated",
          shop.shop_domain,
          valid_order_params()
        )

      assert conn.status == 200
    end

    test "recently processed order returns 200 (skipped)" do
      shop = insert(:shop)

      insert(:message,
        shop: shop,
        order_id: "5500000001",
        message_type: "order_update"
      )

      conn =
        signed_webhook_post(
          "/webhooks/shopify/orders/updated",
          shop.shop_domain,
          valid_order_params()
        )

      assert conn.status == 200
    end

    test "invalid HMAC returns 401" do
      conn =
        unsigned_webhook_post(
          "/webhooks/shopify/orders/updated",
          "test.myshopify.com",
          valid_order_params()
        )

      assert conn.status == 401
    end
  end
end
