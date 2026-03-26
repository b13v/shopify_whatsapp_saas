defmodule ShopifyWhatsapp.MessageTest do
  use ShopifyWhatsapp.DataCase

  import ShopifyWhatsapp.TestFactory

  alias ShopifyWhatsapp.Message

  describe "create_changeset/1" do
    test "valid attributes creates a valid changeset" do
      shop = insert(:shop)
      changeset = Message.create_changeset(%{
        shop_id: shop.id,
        order_id: "5500000001",
        customer_phone: "+15551234567",
        message_type: "order_confirmation",
        status: "pending"
      })

      assert changeset.valid?
    end

    test "requires shop_id" do
      changeset = Message.create_changeset(%{
        order_id: "5500000001",
        customer_phone: "+15551234567",
        message_type: "order_confirmation",
        status: "pending"
      })

      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).shop_id
    end

    test "requires order_id" do
      shop = insert(:shop)
      changeset = Message.create_changeset(%{
        shop_id: shop.id,
        customer_phone: "+15551234567",
        message_type: "order_confirmation",
        status: "pending"
      })

      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).order_id
    end

    test "requires customer_phone" do
      shop = insert(:shop)
      changeset = Message.create_changeset(%{
        shop_id: shop.id,
        order_id: "5500000001",
        message_type: "order_confirmation",
        status: "pending"
      })

      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).customer_phone
    end

    test "requires message_type" do
      shop = insert(:shop)
      changeset = Message.create_changeset(%{
        shop_id: shop.id,
        order_id: "5500000001",
        customer_phone: "+15551234567",
        status: "pending"
      })

      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).message_type
    end

    test "requires status" do
      shop = insert(:shop)
      changeset = Message.create_changeset(%{
        shop_id: shop.id,
        order_id: "5500000001",
        customer_phone: "+15551234567",
        message_type: "order_confirmation"
      })

      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).status
    end

    test "validates phone format (E.164)" do
      shop = insert(:shop)
      for invalid <- ["5551234567", "+05551234567", "abc", "+", "+0"] do
        changeset = Message.create_changeset(%{
          shop_id: shop.id,
          order_id: "5500000001",
          customer_phone: invalid,
          message_type: "order_confirmation",
          status: "pending"
        })
        refute changeset.valid?, "Expected #{inspect(invalid)} to be invalid"
      end
    end

    test "accepts valid E.164 phone numbers" do
      shop = insert(:shop)
      for valid <- ["+15551234567", "+123456789012345"] do
        changeset = Message.create_changeset(%{
          shop_id: shop.id,
          order_id: "5500000001",
          customer_phone: valid,
          message_type: "order_confirmation",
          status: "pending"
        })
        assert changeset.valid?, "Expected #{inspect(valid)} to be valid"
      end
    end

    test "validates status inclusion" do
      shop = insert(:shop)
      changeset = Message.create_changeset(%{
        shop_id: shop.id,
        order_id: "5500000001",
        customer_phone: "+15551234567",
        message_type: "order_confirmation",
        status: "unknown"
      })

      refute changeset.valid?
      assert "is invalid" in errors_on(changeset).status
    end

    test "validates all valid statuses" do
      shop = insert(:shop)
      for status <- ~w(pending sent delivered failed) do
        changeset = Message.create_changeset(%{
          shop_id: shop.id,
          order_id: "5500000001",
          customer_phone: "+15551234567",
          message_type: "order_confirmation",
          status: status
        })
        assert changeset.valid?, "Expected #{status} to be valid"
      end
    end
  end

  describe "status_changeset/2" do
    test "updates status" do
      message = insert(:message)
      changeset = Message.status_changeset(message, %{status: "sent"})
      assert changeset.valid?
    end

    test "rejects invalid status" do
      message = insert(:message)
      changeset = Message.status_changeset(message, %{status: "bogus"})
      refute changeset.valid?
    end
  end

  describe "mark_sent/2" do
    test "sets status to sent" do
      message = insert(:message)
      changeset = Message.mark_sent(message, "wamid_123")
      assert Ecto.Changeset.get_change(changeset, :status) == "sent"
    end

    test "sets sent_at" do
      message = insert(:message)
      changeset = Message.mark_sent(message, "wamid_123")
      assert %DateTime{} = Ecto.Changeset.get_change(changeset, :sent_at)
    end

    test "sets whatsapp_message_id" do
      message = insert(:message)
      changeset = Message.mark_sent(message, "wamid_123")
      assert Ecto.Changeset.get_change(changeset, :whatsapp_message_id) == "wamid_123"
    end

    test "handles nil whatsapp_message_id" do
      message = insert(:message)
      changeset = Message.mark_sent(message)
      assert Ecto.Changeset.get_change(changeset, :whatsapp_message_id) == nil
    end
  end

  describe "mark_delivered/1" do
    test "sets status to delivered" do
      message = insert(:message)
      changeset = Message.mark_delivered(message)
      assert Ecto.Changeset.get_change(changeset, :status) == "delivered"
    end

    test "sets delivered_at" do
      message = insert(:message)
      changeset = Message.mark_delivered(message)
      assert %DateTime{} = Ecto.Changeset.get_change(changeset, :delivered_at)
    end
  end

  describe "mark_failed/2" do
    test "sets status to failed" do
      message = insert(:message)
      changeset = Message.mark_failed(message, "timeout")
      assert Ecto.Changeset.get_change(changeset, :status) == "failed"
    end

    test "sets error_reason" do
      message = insert(:message)
      changeset = Message.mark_failed(message, "API timeout")
      assert Ecto.Changeset.get_change(changeset, :error_reason) == "API timeout"
    end

    test "truncates long error reasons" do
      message = insert(:message)
      long_reason = String.duplicate("a", 600)
      changeset = Message.mark_failed(message, long_reason)
      truncated = Ecto.Changeset.get_change(changeset, :error_reason)
      assert String.length(truncated) == 500
      assert String.ends_with?(truncated, "...")
    end

    test "converts non-binary reason to string" do
      message = insert(:message)
      changeset = Message.mark_failed(message, :timeout)
      assert is_binary(Ecto.Changeset.get_change(changeset, :error_reason))
    end
  end

  describe "increment_retry/1" do
    test "increments from 0 to 1" do
      message = insert(:message)
      changeset = Message.increment_retry(message)
      assert Ecto.Changeset.get_change(changeset, :retry_count) == 1
    end

    test "increments multiple times" do
      message = insert(:message, retry_count: 2)
      changeset = Message.increment_retry(message)
      assert Ecto.Changeset.get_change(changeset, :retry_count) == 3
    end
  end
end
