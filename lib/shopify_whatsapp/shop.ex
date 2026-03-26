defmodule ShopifyWhatsapp.Shop do
  @moduledoc """
  Schema for a Shopify shop that has installed the app.

  Stores the shop's domain, encrypted access token, and WhatsApp configuration.
  """

  use Ecto.Schema
  import Ecto.Changeset
  alias ShopifyWhatsapp.Vault

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @type t :: %__MODULE__{}

  schema "shops" do
    field :shop_domain, :string
    field :access_token, :binary
    field :whatsapp_phone, :string
    field :installed_at, :utc_datetime

    # Webhook tracking
    field :orders_create_webhook_id, :string
    field :orders_updated_webhook_id, :string

    # Virtual field for plain-text token during changeset processing
    field :plain_token, :string, virtual: true

    has_many :messages, ShopifyWhatsapp.Message

    timestamps(type: :utc_datetime)
  end

  @doc """
  Changeset for creating a new shop installation.
  """
  def create_changeset(attrs \\ %{}) do
    %__MODULE__{}
    |> cast(attrs, [:shop_domain, :plain_token, :whatsapp_phone])
    |> validate_required([:shop_domain, :plain_token])
    |> validate_format(:shop_domain, ~r/^[a-zA-Z0-9][a-zA-Z0-9\-]*\.myshopify\.com$/)
    |> unique_constraint(:shop_domain)
    |> put_access_token()
    |> put_installed_at()
  end

  @doc """
  Changeset for updating shop configuration.
  """
  def update_changeset(shop, attrs) do
    shop
    |> cast(attrs, [:whatsapp_phone, :plain_token])
    |> put_access_token()
  end

  @doc """
  Changeset for storing webhook IDs.
  """
  def webhooks_changeset(shop, attrs) do
    shop
    |> cast(attrs, [:orders_create_webhook_id, :orders_updated_webhook_id])
  end

  # Puts the encrypted access token from plain_token
  defp put_access_token(changeset) do
    case get_change(changeset, :plain_token) do
      nil ->
        changeset

      token ->
        encrypted_token = Vault.encrypt!(token)
        put_change(changeset, :access_token, encrypted_token)
    end
  end

  # Sets the installation timestamp
  defp put_installed_at(changeset) do
    case get_field(changeset, :installed_at) do
      nil ->
        put_change(changeset, :installed_at, DateTime.utc_now() |> DateTime.truncate(:second))

      _ ->
        changeset
    end
  end

  @doc """
  Normalizes a shop domain to myshopify.com format.
  """
  @spec normalize_domain(String.t()) :: String.t()
  def normalize_domain(domain) do
    domain
    |> String.trim()
    |> String.downcase()
    |> String.replace_prefix("https://", "")
    |> String.replace_prefix("http://", "")
    |> String.replace_suffix("/", "")
    |> then(fn
      d -> if String.contains?(d, "."), do: d, else: d <> ".myshopify.com"
    end)
  end

  @doc """
  Returns the decrypted access token for API requests.
  """
  @spec get_access_token(t()) :: String.t()
  def get_access_token(%__MODULE__{access_token: encrypted_token}) do
    Vault.decrypt!(encrypted_token)
  end
end
