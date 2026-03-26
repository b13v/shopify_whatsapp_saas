Application.ensure_all_started(:mox)
ShopifyWhatsapp.Vault.start_link()

ExUnit.start()
Ecto.Adapters.SQL.Sandbox.mode(ShopifyWhatsapp.Repo, :manual)
