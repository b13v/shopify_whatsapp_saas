defmodule ShopifyWhatsapp.Repo.Migrations.CreateMessages do
  use Ecto.Migration

  def change do
    create table(:messages, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :shop_id, references(:shops, type: :binary_id, on_delete: :delete_all), null: false
      add :order_id, :string, null: false
      add :customer_phone, :string, null: false
      add :message_type, :string, null: false
      add :status, :string, default: "pending", null: false
      add :sent_at, :utc_datetime
      add :delivered_at, :utc_datetime
      add :error_reason, :text
      add :whatsapp_message_id, :string
      add :retry_count, :integer, default: 0

      timestamps(type: :utc_datetime)
    end

    create index(:messages, [:shop_id, :status])
    create index(:messages, [:order_id])
    create index(:messages, [:status])
    create index(:messages, [:inserted_at])
  end
end
