defmodule ShopifyWhatsappWeb.CacheBodyReader do
  @moduledoc """
  Body reader that caches the raw request body for later use.

  This is needed by ShopifyWebhookPlug which must read the raw body
  to verify HMAC signatures, but runs after Plug.Parsers which would
  otherwise consume the body.
  """

  @spec read_body(Plug.Conn.t(), Keyword.t()) :: {:ok, binary(), Plug.Conn.t()} | {:error, term()}
  def read_body(conn, opts) do
    case Plug.Conn.read_body(conn, opts) do
      {:ok, body, conn} ->
        conn = Plug.Conn.assign(conn, :raw_body, body)
        {:ok, body, conn}

      {:error, reason} ->
        {:error, reason}
    end
  end
end
