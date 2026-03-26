defmodule ShopifyWhatsapp.Repo.Migrations.CreateShops do
  use Ecto.Migration

  def change do
    create table(:shops, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :shop_domain, :string, null: false
      add :access_token, :binary, null: false
      add :whatsapp_phone, :string
      add :installed_at, :utc_datetime
      add :orders_create_webhook_id, :string
      add :orders_updated_webhook_id, :string

      timestamps(type: :utc_datetime)
    end

    create unique_index(:shops, [:shop_domain])
  end
end
