defmodule ShopifyWhatsapp.Vault do
  @moduledoc """
  Encryption vault for sensitive data using Cloak.

  This vault handles encryption and decryption of sensitive fields like
  Shopify access tokens.
  """
  use Cloak.Vault, otp_app: :shopify_whatsapp
end
