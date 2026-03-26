defmodule ShopifyWhatsapp.TelemetryTest do
  use ExUnit.Case

  import ExUnit.CaptureLog

  alias ShopifyWhatsapp.Telemetry

  describe "log_shopify_error/3" do
    test "logs with :shopify_api event type" do
      log =
        capture_log([level: :error], fn ->
          Telemetry.log_shopify_error("fetch_order", :timeout, %{shop: "test"})
        end)

      assert log =~ "shopify_api"
      assert log =~ "fetch_order"
    end
  end

  describe "log_whatsapp_error/3" do
    test "logs with :whatsapp_api event type" do
      log =
        capture_log([level: :error], fn ->
          Telemetry.log_whatsapp_error("send_message", :rate_limited)
        end)

      assert log =~ "whatsapp_api"
      assert log =~ "send_message"
    end
  end

  describe "log_job_failure/4" do
    test "redacts access_token in args" do
      log =
        capture_log([level: :error], fn ->
          Telemetry.log_job_failure("TestWorker", %{"access_token" => "secret"}, :failed)
        end)

      assert log =~ "[REDACTED]"
      refute log =~ "secret"
    end

    test "redacts plain_token in args" do
      log =
        capture_log([level: :error], fn ->
          Telemetry.log_job_failure("TestWorker", %{"plain_token" => "shpat_xxx"}, :failed)
        end)

      assert log =~ "[REDACTED]"
      refute log =~ "shpat_xxx"
    end

    test "redacts token key in args" do
      log =
        capture_log([level: :error], fn ->
          Telemetry.log_job_failure("TestWorker", %{"token" => "Bearer xyz"}, :failed)
        end)

      assert log =~ "[REDACTED]"
      refute log =~ "Bearer xyz"
    end

    test "keeps non-sensitive args intact" do
      log =
        capture_log([level: :error], fn ->
          Telemetry.log_job_failure("TestWorker", %{"order_id" => "123"}, :failed)
        end)

      assert log =~ "123"
      assert log =~ "job_failure"
    end
  end

  describe "log_webhook_received/3" do
    test "logs webhook event" do
      Logger.configure(level: :info)

      log =
        capture_log(fn ->
          Telemetry.log_webhook_received("test.myshopify.com", "orders/create", "5501")
        end)

      assert log =~ "webhook_received"
      assert log =~ "test.myshopify.com"
      assert log =~ "orders/create"
      assert log =~ "5501"
    after
      Logger.configure(level: :warning)
    end
  end

  describe "log_webhook_processed/4" do
    test "logs processing result" do
      Logger.configure(level: :info)

      log =
        capture_log(fn ->
          Telemetry.log_webhook_processed("test.myshopify.com", "orders/create", "5501", :ok)
        end)

      assert log =~ "webhook_processed"
      assert log =~ ":ok"
    after
      Logger.configure(level: :warning)
    end
  end
end
