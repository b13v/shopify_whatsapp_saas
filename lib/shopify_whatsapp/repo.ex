defmodule ShopifyWhatsapp.Repo do
  use Ecto.Repo,
    otp_app: :shopify_whatsapp,
    adapter: Ecto.Adapters.Postgres
end
