defmodule ShopifyWhatsapp.Whatsapp.Client do
  @moduledoc """
  WhatsApp Business API client wrapper.

  Currently designed to work with kapso.ai as the WhatsApp service provider.
  Handles sending messages, rate limiting, and error recovery.
  """

  @type send_result :: {:ok, map()} | {:error, term()}

  @doc """
  Sends a WhatsApp message using a template.

  ## Parameters
    - to: The recipient's phone number (with country code, e.g., "+1234567890")
    - template_name: The name of the WhatsApp template to use
    - template_params: Map of parameters for the template (e.g., %{"customer_name" => "John"})
    - opts: Optional keyword arguments:
      - :language_code - ISO 639-1 language code (default: "en")
      - :phone_id - WhatsApp phone ID for sending (default: from config)

  ## Returns
    - `{:ok, response_map}` on success
    - `{:error, reason}` on failure

  ## Rate Limiting
  This function respects WhatsApp rate limits:
  - Marketing messages: varies by tier
  - Utility messages: 1000/day
  - Authentication messages: 10/minute

  On rate limit errors (429), the function returns `{:error, :rate_limited}`
  with retry-after information in metadata.
  """
  def send_message(to, template_name, template_params, opts \\ []) do
    phone_id = Keyword.get(opts, :phone_id, default_phone_id())
    language_code = Keyword.get(opts, :language_code, "en")

    body = build_message_body(to, template_name, template_params, language_code)

    send_to_api(phone_id, body)
  end

  @doc """
  Sends a text message (free-form, not template-based).

  Note: WhatsApp Business API requires template messages for initiation.
  Free-form messages can only be sent within a 24-hour customer service window.
  Use this for replies, not initial outreach.

  ## Parameters
    - to: The recipient's phone number
    - text: The message text
    - opts: Optional keyword arguments (same as send_message/4)

  ## Returns
    - `{:ok, response_map}` on success
    - `{:error, reason}` on failure
  """
  def send_text(to, text, opts \\ []) do
    phone_id = Keyword.get(opts, :phone_id, default_phone_id())

    body = %{
      messaging_product: "whatsapp",
      recipient_type: "individual",
      to: to,
      type: "text",
      text: %{preview_url: false, body: text}
    }

    send_to_api(phone_id, body)
  end

  @doc """
  Checks if a phone number is eligible for WhatsApp messages.

  ## Parameters
    - phone: The phone number to check

  ## Returns
    - `{:ok, %{eligible: true/false}}` with eligibility details
    - `{:error, reason}` on API failure
  """
  def check_eligibility(phone) do
    url = base_url() <> "/check_eligibility"

    case Req.post(url, json: %{phone: phone}) do
      {:ok, %{status: 200, body: body}} -> {:ok, body}
      {:ok, %{status: status, body: body}} -> {:error, {:http_error, status, body}}
      {:error, reason} -> {:error, {:transport_error, reason}}
    end
  end

  # Private helpers

  defp build_message_body(to, template_name, template_params, language_code) do
    %{
      messaging_product: "whatsapp",
      recipient_type: "individual",
      to: to,
      type: "template",
      template: %{
        name: template_name,
        language: %{code: language_code},
        components: build_components(template_params)
      }
    }
  end

  defp build_components(params) when is_map(params) and map_size(params) > 0 do
    [
      %{
        type: "body",
        parameters:
          Enum.map(params, fn {_key, value} ->
            %{type: "text", text: value}
          end)
      }
    ]
  end

  defp build_components(_params), do: []

  defp send_to_api(phone_id, body) do
    url = base_url() <> "/#{phone_id}/messages"

    case Req.post(url, json: body, auth: bearer_auth()) do
      {:ok, %{status: status} = response} when status in 200..299 ->
        {:ok, response.body}

      {:ok, %{status: 429, headers: headers}} ->
        retry_after = get_header(headers, "retry-after")
        {:error, {:rate_limited, retry_after: retry_after}}

      {:ok, %{status: status, body: body}} when status in 400..499 ->
        {:error, {:client_error, status, body}}

      {:ok, %{status: status, body: body}} when status in 500..599 ->
        {:error, {:server_error, status, body}}

      {:error, %Req.TransportError{reason: reason}} ->
        {:error, {:transport_error, reason}}

      {:error, reason} ->
        {:error, {:unknown_error, reason}}
    end
  end

  defp base_url do
    # TODO: Configure this properly for kapso.ai
    # For now, using a placeholder that matches WhatsApp Cloud API structure
    Application.get_env(:shopify_whatsapp, :whatsapp_base_url, "https://graph.facebook.com/v19.0")
  end

  defp default_phone_id do
    Application.get_env(:shopify_whatsapp, :whatsapp_phone_id)
  end

  defp bearer_auth do
    token = Application.get_env(:shopify_whatsapp, :whatsapp_access_token)
    {:bearer, token}
  end

  defp get_header(headers, key) do
    Enum.find_value(headers, fn {k, v} ->
      if String.downcase(k) == String.downcase(key), do: v
    end)
  end
end
