defmodule ShopifyWhatsapp.ShopTest do
  use ShopifyWhatsapp.DataCase

  import ShopifyWhatsapp.TestFactory

  alias ShopifyWhatsapp.Shop

  describe "create_changeset/1" do
    test "valid attributes creates a valid changeset" do
      changeset = Shop.create_changeset(%{
        shop_domain: "my-store.myshopify.com",
        plain_token: "shpat_test_token",
        whatsapp_phone: "+1234567890"
      })

      assert changeset.valid?
    end

    test "requires shop_domain" do
      changeset = Shop.create_changeset(%{plain_token: "shpat_test_token"})
      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).shop_domain
    end

    test "requires plain_token" do
      changeset = Shop.create_changeset(%{shop_domain: "my-store.myshopify.com"})
      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).plain_token
    end

    test "validates shop_domain format" do
      for invalid <- ["not a domain", "my store.myshopify.com", "http://bad.com", "evil.com"] do
        changeset = Shop.create_changeset(%{shop_domain: invalid, plain_token: "tok"})
        refute changeset.valid?, "Expected #{inspect(invalid)} to be invalid"
      end
    end

    test "accepts valid shop_domain formats" do
      for valid <- ["my-store.myshopify.com", "A1.myshopify.com", "a-b-c.myshopify.com"] do
        changeset = Shop.create_changeset(%{shop_domain: valid, plain_token: "tok"})
        assert changeset.valid?, "Expected #{inspect(valid)} to be valid"
      end
    end

    test "encrypted token is stored in access_token" do
      changeset = Shop.create_changeset(%{
        shop_domain: "my-store.myshopify.com",
        plain_token: "shpat_secret_token"
      })

      assert Ecto.Changeset.get_change(changeset, :access_token) != "shpat_secret_token"
      assert is_binary(Ecto.Changeset.get_change(changeset, :access_token))
    end

    test "installed_at is set on creation" do
      changeset = Shop.create_changeset(%{
        shop_domain: "my-store.myshopify.com",
        plain_token: "shpat_test_token"
      })

      assert %DateTime{} = Ecto.Changeset.get_change(changeset, :installed_at)
    end

    test "enforces unique shop_domain" do
      shop = insert(:shop)
      {:error, changeset} =
        Shop.create_changeset(%{shop_domain: shop.shop_domain, plain_token: "tok"})
        |> Repo.insert()

      refute changeset.valid?
      assert "has already been taken" in errors_on(changeset).shop_domain
    end
  end

  describe "update_changeset/2" do
    test "updates whatsapp_phone" do
      shop = insert(:shop)
      changeset = Shop.update_changeset(shop, %{whatsapp_phone: "+9876543210"})
      assert changeset.valid?
      assert Ecto.Changeset.get_change(changeset, :whatsapp_phone) == "+9876543210"
    end

    test "re-encrypts access token" do
      shop = insert(:shop)
      changeset = Shop.update_changeset(shop, %{plain_token: "shpat_new_token"})
      assert is_binary(Ecto.Changeset.get_change(changeset, :access_token))
    end

    test "does not encrypt when plain_token is not provided" do
      shop = insert(:shop)
      changeset = Shop.update_changeset(shop, %{whatsapp_phone: "+9876543210"})
      assert changeset.valid?
      assert nil == Ecto.Changeset.get_change(changeset, :access_token)
    end
  end

  describe "webhooks_changeset/2" do
    test "stores webhook IDs" do
      shop = insert(:shop)
      changeset = Shop.webhooks_changeset(shop, %{
        orders_create_webhook_id: "12345",
        orders_updated_webhook_id: "67890"
      })
      assert changeset.valid?
    end
  end

  describe "normalize_domain/1" do
    test "strips https:// prefix" do
      assert Shop.normalize_domain("https://my-store.myshopify.com") ==
               "my-store.myshopify.com"
    end

    test "strips http:// prefix" do
      assert Shop.normalize_domain("http://my-store.myshopify.com") ==
               "my-store.myshopify.com"
    end

    test "lowercases domain" do
      assert Shop.normalize_domain("MY-STORE.myshopify.com") ==
               "my-store.myshopify.com"
    end

    test "strips trailing slash" do
      assert Shop.normalize_domain("my-store.myshopify.com/") ==
               "my-store.myshopify.com"
    end

    test "appends .myshopify.com when no dot present" do
      assert Shop.normalize_domain("my-store") == "my-store.myshopify.com"
    end

    test "leaves complete domain untouched" do
      assert Shop.normalize_domain("my-store.myshopify.com") ==
               "my-store.myshopify.com"
    end

    test "handles combination of prefixes and slashes" do
      assert Shop.normalize_domain("  HTTPS://My-Store.MyShopify.Com/  ") ==
               "my-store.myshopify.com"
    end
  end

  describe "get_access_token/1" do
    test "round-trips encrypt/decrypt" do
      {:ok, shop} =
        Shop.create_changeset(%{
          shop_domain: "get-token-test.myshopify.com",
          plain_token: "shpat_my_secret"
        })
        |> Repo.insert()

      assert Shop.get_access_token(shop) == "shpat_my_secret"
    end
  end
end
