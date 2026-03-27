defmodule ShopifyWhatsappWeb.SettingsLive do
  use ShopifyWhatsappWeb, :live_view

  on_mount {ShopifyWhatsappWeb.LiveAuth, :default}

  alias ShopifyWhatsapp.{Repo, Shop}

  @impl true
  def mount(_params, _session, socket) do
    case socket.assigns[:current_shop] do
      nil ->
        {:ok, assign(socket, %{shop: nil, changeset: nil, saved: false})}

      shop ->
        changeset = Shop.settings_changeset(shop, %{})

        {:ok,
         socket
         |> assign(:shop, shop)
         |> assign(:changeset, changeset)
         |> assign(:saved, false)}
    end
  end

  @impl true
  def handle_event("validate", %{"shop" => params}, socket) do
    changeset =
      socket.assigns.shop
      |> Shop.settings_changeset(params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :changeset, changeset)}
  end

  @impl true
  def handle_event("save", %{"shop" => params}, socket) do
    shop = socket.assigns.shop

    case shop |> Shop.settings_changeset(params) |> Repo.update() do
      {:ok, updated_shop} ->
        {:noreply,
         socket
         |> assign(:shop, updated_shop)
         |> assign(:changeset, Shop.settings_changeset(updated_shop, %{}))
         |> assign(:saved, true)}

      {:error, changeset} ->
        {:noreply, assign(socket, :changeset, Map.put(changeset, :action, :update))}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.dashboard_layout current_shop={@shop} active_tab="settings" flash={@flash}>
      <%= if @shop do %>
        <div class="max-w-3xl mx-auto px-4 py-8 sm:px-6 lg:px-8">
          <!-- Success Banner -->
          <%= if @saved do %>
            <div class="mb-6 rounded-lg bg-green-50 border border-green-200 p-4">
              <div class="flex">
                <svg class="h-5 w-5 text-green-400 flex-shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
                </svg>
                <div class="ml-3">
                  <h3 class="text-sm font-medium text-green-800">You're all set!</h3>
                  <p class="mt-1 text-sm text-green-700">
                    WhatsApp notifications will be sent to
                    <span class="font-medium"><%= @shop.whatsapp_phone || "not configured yet" %></span>
                    when customers place orders.
                  </p>
                </div>
              </div>
            </div>
          <% end %>

          <!-- WhatsApp Configuration -->
          <div class="bg-white shadow rounded-lg">
            <div class="px-4 py-5 border-b border-gray-200 sm:px-6">
              <h3 class="text-lg leading-6 font-medium text-gray-900">WhatsApp Configuration</h3>
              <p class="mt-1 text-sm text-gray-500">
                Configure the phone number used to send WhatsApp notifications to customers.
              </p>
            </div>
            <div class="px-4 py-5 sm:p-6">
              <.form
                for={@changeset}
                id="settings-form"
                phx-submit="save"
                phx-change="validate"
              >
                <div class="space-y-6">
                  <div>
                    <label for="shop_whatsapp_phone" class="block text-sm font-medium text-gray-700">
                      WhatsApp Phone Number
                    </label>
                    <div class="mt-1">
                      <input
                        type="tel"
                        name="shop[whatsapp_phone]"
                        id="shop_whatsapp_phone"
                        value={Ecto.Changeset.get_field(@changeset, :whatsapp_phone)}
                        placeholder="+1234567890"
                        class="shadow-sm focus:ring-green-500 focus:border-green-500 block w-full sm:text-sm border-gray-300 rounded-md"
                      />
                    </div>
                    <p class="mt-2 text-sm text-gray-500">
                      Include country code, e.g. +1234567890
                    </p>
                  </div>

                  <div class="flex justify-end">
                    <button
                      type="submit"
                      class="ml-3 inline-flex justify-center py-2 px-4 border border-transparent shadow-sm text-sm font-medium rounded-md text-white bg-green-600 hover:bg-green-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-green-500"
                    >
                      Save Changes
                    </button>
                  </div>
                </div>
              </.form>
            </div>
          </div>

          <!-- Shop Information (muted footer) -->
          <div class="mt-6 rounded-lg bg-gray-50 border border-gray-200 px-4 py-4 sm:px-6">
            <h4 class="text-xs font-semibold text-gray-500 uppercase tracking-wider mb-3">
              Shop Information
            </h4>
            <dl class="grid grid-cols-2 gap-x-4 gap-y-2 text-sm">
              <div>
                <dt class="font-medium text-gray-500">Shop Domain</dt>
                <dd class="text-gray-900"><%= @shop.shop_domain %></dd>
              </div>
              <div>
                <dt class="font-medium text-gray-500">Installed</dt>
                <dd class="text-gray-900">
                  <%= if @shop.installed_at, do: Calendar.strftime(@shop.installed_at, "%Y-%m-%d %H:%M"), else: "N/A" %>
                </dd>
              </div>
              <div>
                <dt class="font-medium text-gray-500">Create Webhook</dt>
                <dd class="text-gray-900">
                  <%= if @shop.orders_create_webhook_id do %>
                    <span class="inline-flex items-center px-2 py-0.5 rounded text-xs font-medium bg-green-100 text-green-800">
                      Registered
                    </span>
                  <% else %>
                    <span class="inline-flex items-center px-2 py-0.5 rounded text-xs font-medium bg-gray-200 text-gray-600">
                      Not registered
                    </span>
                  <% end %>
                </dd>
              </div>
              <div>
                <dt class="font-medium text-gray-500">Update Webhook</dt>
                <dd class="text-gray-900">
                  <%= if @shop.orders_updated_webhook_id do %>
                    <span class="inline-flex items-center px-2 py-0.5 rounded text-xs font-medium bg-green-100 text-green-800">
                      Registered
                    </span>
                  <% else %>
                    <span class="inline-flex items-center px-2 py-0.5 rounded text-xs font-medium bg-gray-200 text-gray-600">
                      Not registered
                    </span>
                  <% end %>
                </dd>
              </div>
            </dl>
          </div>
        </div>
      <% end %>
    </.dashboard_layout>
    """
  end
end
