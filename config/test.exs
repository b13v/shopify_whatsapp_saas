import Config

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :shopify_whatsapp, ShopifyWhatsapp.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "shopify_whatsapp_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :shopify_whatsapp, ShopifyWhatsappWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "6Xy78tMHcrZ8hJEGkanmAq8u/P1TLmahVYXyZqOQE6XQzSNrHJmzLlSyHFukwH1b",
  server: false

# In test we don't send emails.
config :shopify_whatsapp, ShopifyWhatsapp.Mailer, adapter: Swoosh.Adapters.Test

# Disable swoosh api client as it is only required for production adapters.
config :swoosh, :api_client, false

# Print only warnings and errors during test
# Shopify API credentials for install controller tests
config :shopify_whatsapp, :shopify_api_key, "test_api_key"
config :shopify_whatsapp, :shopify_api_secret, "test_api_secret"
config :shopify_whatsapp, :shopify_webhook_secret, "test_webhook_secret"

# WhatsApp API config for tests
config :shopify_whatsapp, :whatsapp_base_url, "https://graph.facebook.com/v19.0"
config :shopify_whatsapp, :whatsapp_phone_id, "test_phone_id"
config :shopify_whatsapp, :whatsapp_access_token, "test_whatsapp_token"

config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

# Oban testing configuration - use fake queue for tests
config :shopify_whatsapp, Oban,
  repo: ShopifyWhatsapp.Repo,
  queues: false,
  prefix: "oban",
  testing: :manual

# Cloak encryption key for testing (32 bytes base64 encoded)
config :shopify_whatsapp, :cloak_key, "ZKbCL9Ix5w6uNV6xIZ8lHJ8LNLoC0P0BWyxIl3GIG8A="

# Cloak vault configuration with cipher
config :shopify_whatsapp, ShopifyWhatsapp.Vault,
  ciphers: [
    default:
      {Cloak.Ciphers.AES.GCM,
       tag: "AES.GCM.V1",
       key: Base.decode64!("ZKbCL9Ix5w6uNV6xIZ8lHJ8LNLoC0P0BWyxIl3GIG8A="),
       iv_length: 12}
  ]
