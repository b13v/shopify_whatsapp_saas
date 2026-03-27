defmodule ShopifyWhatsappWeb.SettingsLive do
  use ShopifyWhatsappWeb, :live_view

  on_mount {ShopifyWhatsappWeb.LiveAuth, :default}

  alias ShopifyWhatsapp.{Repo, Shop}

  @impl true
  def mount(_params, _session, socket) do
    case socket.assigns[:current_shop] do
      nil ->
        {:ok, assign(socket, %{shop: nil, changeset: nil})}

      shop ->
        changeset = Shop.settings_changeset(shop, %{})

        {:ok,
         socket
         |> assign(:shop, shop)
         |> assign(:changeset, changeset)}
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
         |> put_flash(:info, "Settings saved successfully.")}

      {:error, changeset} ->
        {:noreply, assign(socket, :changeset, Map.put(changeset, :action, :insert))}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.dashboard_layout current_shop={@shop} active_tab="settings">
      <div class="max-w-3xl mx-auto px-4 py-8 sm:px-6 lg:px-8">
        <!-- WhatsApp Configuration -->
        <div class="bg-white shadow rounded-lg mb-8">
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
                      class="shadow-sm focus:ring-blue-500 focus:border-blue-500 block w-full sm:text-sm border-gray-300 rounded-md"
                    />
                  </div>
                  <p class="mt-2 text-sm text-gray-500">
                    Include country code, e.g. +1234567890
                  </p>
                  <%= if error = @changeset.errors[:whatsapp_phone] do %>
                    <p class="mt-2 text-sm text-red-600">
                      <%= error |> elem(0) %>
                    </p>
                  <% end %>
                </div>

                <div class="flex justify-end">
                  <button
                    type="submit"
                    class="ml-3 inline-flex justify-center py-2 px-4 border border-transparent shadow-sm text-sm font-medium rounded-md text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500"
                  >
                    Save Changes
                  </button>
                </div>
              </div>
            </.form>
          </div>
        </div>

        <!-- Shop Information -->
        <div class="bg-white shadow rounded-lg">
          <div class="px-4 py-5 border-b border-gray-200 sm:px-6">
            <h3 class="text-lg leading-6 font-medium text-gray-900">Shop Information</h3>
          </div>
          <div class="px-4 py-5 sm:p-6">
            <dl class="grid grid-cols-1 gap-x-4 gap-y-6 sm:grid-cols-2">
              <div>
                <dt class="text-sm font-medium text-gray-500">Shop Domain</dt>
                <dd class="mt-1 text-sm text-gray-900"><%= @shop.shop_domain %></dd>
              </div>

              <div>
                <dt class="text-sm font-medium text-gray-500">Installed At</dt>
                <dd class="mt-1 text-sm text-gray-900">
                  <%= if @shop.installed_at, do: Calendar.strftime(@shop.installed_at, "%Y-%m-%d %H:%M"), else: "N/A" %>
                </dd>
              </div>

              <div>
                <dt class="text-sm font-medium text-gray-500">Orders Create Webhook</dt>
                <dd class="mt-1">
                  <%= if @shop.orders_create_webhook_id do %>
                    <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-green-100 text-green-800">
                      Registered
                    </span>
                  <% else %>
                    <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-gray-100 text-gray-800">
                      Not registered
                    </span>
                  <% end %>
                </dd>
              </div>

              <div>
                <dt class="text-sm font-medium text-gray-500">Orders Updated Webhook</dt>
                <dd class="mt-1">
                  <%= if @shop.orders_updated_webhook_id do %>
                    <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-green-100 text-green-800">
                      Registered
                    </span>
                  <% else %>
                    <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-gray-100 text-gray-800">
                      Not registered
                    </span>
                  <% end %>
                </dd>
              </div>
            </dl>
          </div>
        </div>
      </div>
    </.dashboard_layout>
    """
  end
end
