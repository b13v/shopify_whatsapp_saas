defmodule ShopifyWhatsapp.Message do
  @moduledoc """
  Schema for WhatsApp messages sent through the app.

  Tracks order notifications and their delivery status.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @type t :: %__MODULE__{}

  schema "messages" do
    field :order_id, :string
    field :customer_phone, :string
    field :message_type, :string
    field :status, :string
    field :sent_at, :utc_datetime
    field :delivered_at, :utc_datetime
    field :error_reason, :string

    # API response tracking
    field :whatsapp_message_id, :string
    field :retry_count, :integer, default: 0

    belongs_to :shop, ShopifyWhatsapp.Shop

    timestamps(type: :utc_datetime)
  end

  @doc """
  Changeset for creating a new message.
  """
  def create_changeset(attrs \\ %{}) do
    %__MODULE__{}
    |> cast(attrs, [:shop_id, :order_id, :customer_phone, :message_type, :status])
    |> validate_required([:shop_id, :order_id, :customer_phone, :message_type, :status])
    |> validate_inclusion(:status, ~w(pending sent delivered failed))
    |> validate_format(:customer_phone, ~r/^\+[1-9]\d{1,14}$/)
    |> assoc_constraint(:shop)
  end

  @doc """
  Changeset for updating message status.
  """
  def status_changeset(message, attrs) do
    message
    |> cast(attrs, [:status, :sent_at, :delivered_at, :error_reason, :whatsapp_message_id])
    |> validate_inclusion(:status, ~w(pending sent delivered failed))
  end

  @doc """
  Marks a message as sent.
  """
  def mark_sent(message, whatsapp_message_id \\ nil) do
    message
    |> status_changeset(%{
      status: "sent",
      sent_at: DateTime.utc_now() |> DateTime.truncate(:second),
      whatsapp_message_id: whatsapp_message_id
    })
  end

  @doc """
  Marks a message as delivered.
  """
  def mark_delivered(message) do
    message
    |> status_changeset(%{
      status: "delivered",
      delivered_at: DateTime.utc_now() |> DateTime.truncate(:second)
    })
  end

  @doc """
  Marks a message as failed with a reason.
  """
  def mark_failed(message, reason) do
    message
    |> status_changeset(%{
      status: "failed",
      error_reason: truncate_reason(reason)
    })
  end

  @doc """
  Increments the retry count.
  """
  def increment_retry(message) do
    change(message, retry_count: message.retry_count + 1)
  end

  # Truncates error reason to fit in database column
  defp truncate_reason(reason) when is_binary(reason) do
    if String.length(reason) > 500 do
      String.slice(reason, 0, 497) <> "..."
    else
      reason
    end
  end

  defp truncate_reason(reason), do: inspect(reason)
end
