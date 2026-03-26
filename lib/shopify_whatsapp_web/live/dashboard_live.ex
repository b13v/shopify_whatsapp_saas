defmodule ShopifyWhatsappWeb.DashboardLive do
  use ShopifyWhatsappWeb, :live_view

  require Logger

  alias ShopifyWhatsapp.Dashboard

  @impl true
  def mount(_params, _session, socket) do
    # For MVP, we'll require shop query param
    # In production, use proper session-based auth
    {:ok, assign(socket, %{shop: nil, stats: nil, messages: [], loading: true})}
  end

  @impl true
  def handle_params(%{"shop" => shop_domain}, _uri, socket) do
    case Dashboard.get_shop_by_domain(shop_domain) do
      nil ->
        # Shop not found
        {:noreply,
         socket
         |> put_flash(:error, "Shop not installed. Please install the app first.")
         |> redirect(to: "/")}

      shop ->
        # Load dashboard data
        stats = Dashboard.message_stats(shop.id)
        messages = Dashboard.recent_messages(shop.id, limit: 20)

        {:noreply,
         socket
         |> assign(:shop, shop)
         |> assign(:stats, stats)
         |> assign(:messages, messages)
         |> assign(:loading, false)}
    end
  end

  def handle_params(_params, _uri, socket) do
    # No shop param - redirect to home
    {:noreply, redirect(socket, to: "/")}
  end

  @impl true
  def handle_event("filter_messages", %{"status" => status}, socket) do
    shop = socket.assigns.shop

    messages =
      if status == "all" do
        Dashboard.recent_messages(shop.id, limit: 20)
      else
        Dashboard.recent_messages(shop.id, limit: 20, status: status)
      end

    {:noreply, assign(socket, :messages, messages)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gray-50">
      <!-- Header -->
      <header class="bg-white shadow">
        <div class="max-w-7xl mx-auto px-4 py-6 sm:px-6 lg:px-8">
          <div class="flex justify-between items-center">
            <div>
              <h1 class="text-3xl font-bold text-gray-900">Dashboard</h1>
              <p class="mt-1 text-sm text-gray-500"><%= @shop && @shop.shop_domain %></p>
            </div>
            <%= if @shop do %>
              <button
                phx-click="refresh"
                class="px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700"
              >
                Refresh
              </button>
            <% end %>
          </div>
        </div>
      </header>

      <%= if @loading do %>
        <div class="max-w-7xl mx-auto px-4 py-12 sm:px-6 lg:px-8">
          <p class="text-center text-gray-500">Loading...</p>
        </div>
      <% else %>
        <!-- Stats Cards -->
        <div class="max-w-7xl mx-auto px-4 py-8 sm:px-6 lg:px-8">
          <div class="grid grid-cols-1 gap-5 sm:grid-cols-2 lg:grid-cols-4">
            <!-- Messages Sent -->
            <div class="bg-white overflow-hidden shadow rounded-lg">
              <div class="p-5">
                <div class="flex items-center">
                  <div class="flex-shrink-0">
                    <svg
                      class="h-6 w-6 text-gray-400"
                      fill="none"
                      viewBox="0 0 24 24"
                      stroke="currentColor"
                    >
                      <path
                        stroke-linecap="round"
                        stroke-linejoin="round"
                        stroke-width="2"
                        d="M12 19l9 2-9-18-9 18 9-2zm0 0v-8"
                      />
                    </svg>
                  </div>
                  <div class="ml-5 w-0 flex-1">
                    <dl>
                      <dt class="text-sm font-medium text-gray-500 truncate">Messages Sent</dt>
                      <dd class="text-lg font-medium text-gray-900"><%= @stats.sent %></dd>
                    </dl>
                  </div>
                </div>
              </div>
            </div>
            <!-- Delivery Rate -->
            <div class="bg-white overflow-hidden shadow rounded-lg">
              <div class="p-5">
                <div class="flex items-center">
                  <div class="flex-shrink-0">
                    <svg
                      class="h-6 w-6 text-green-400"
                      fill="none"
                      viewBox="0 0 24 24"
                      stroke="currentColor"
                    >
                      <path
                        stroke-linecap="round"
                        stroke-linejoin="round"
                        stroke-width="2"
                        d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"
                      />
                    </svg>
                  </div>
                  <div class="ml-5 w-0 flex-1">
                    <dl>
                      <dt class="text-sm font-medium text-gray-500 truncate">Delivery Rate</dt>
                      <dd class="text-lg font-medium text-gray-900"><%= @stats.delivery_rate %>%</dd>
                    </dl>
                  </div>
                </div>
              </div>
            </div>
            <!-- Failed -->
            <div class="bg-white overflow-hidden shadow rounded-lg">
              <div class="p-5">
                <div class="flex items-center">
                  <div class="flex-shrink-0">
                    <svg
                      class="h-6 w-6 text-red-400"
                      fill="none"
                      viewBox="0 0 24 24"
                      stroke="currentColor"
                    >
                      <path
                        stroke-linecap="round"
                        stroke-linejoin="round"
                        stroke-width="2"
                        d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"
                      />
                    </svg>
                  </div>
                  <div class="ml-5 w-0 flex-1">
                    <dl>
                      <dt class="text-sm font-medium text-gray-500 truncate">Failed</dt>
                      <dd class="text-lg font-medium text-gray-900"><%= @stats.failed %></dd>
                    </dl>
                  </div>
                </div>
              </div>
            </div>
            <!-- Pending -->
            <div class="bg-white overflow-hidden shadow rounded-lg">
              <div class="p-5">
                <div class="flex items-center">
                  <div class="flex-shrink-0">
                    <svg
                      class="h-6 w-6 text-yellow-400"
                      fill="none"
                      viewBox="0 0 24 24"
                      stroke="currentColor"
                    >
                      <path
                        stroke-linecap="round"
                        stroke-linejoin="round"
                        stroke-width="2"
                        d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"
                      />
                    </svg>
                  </div>
                  <div class="ml-5 w-0 flex-1">
                    <dl>
                      <dt class="text-sm font-medium text-gray-500 truncate">Pending</dt>
                      <dd class="text-lg font-medium text-gray-900"><%= @stats.pending %></dd>
                    </dl>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
        <!-- Messages Table -->
        <div class="max-w-7xl mx-auto px-4 py-8 sm:px-6 lg:px-8">
          <div class="bg-white shadow rounded-lg">
            <div class="px-4 py-5 border-b border-gray-200 sm:px-6">
              <div class="flex justify-between items-center">
                <h3 class="text-lg leading-6 font-medium text-gray-900">Recent Messages</h3>
                <form phx-change="filter_messages">
                  <select
                    name="status"
                    class="mt-1 block pl-3 pr-10 py-2 text-base border-gray-300 focus:outline-none focus:ring-blue-500 focus:border-blue-500 sm:text-sm rounded-md"
                  >
                    <option value="all">All Status</option>
                    <option value="pending">Pending</option>
                    <option value="sent">Sent</option>
                    <option value="delivered">Delivered</option>
                    <option value="failed">Failed</option>
                  </select>
                </form>
              </div>
            </div>
            <div class="overflow-x-auto">
              <table class="min-w-full divide-y divide-gray-200">
                <thead class="bg-gray-50">
                  <tr>
                    <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                      Order ID
                    </th>
                    <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                      Customer Phone
                    </th>
                    <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                      Type
                    </th>
                    <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                      Status
                    </th>
                    <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                      Sent At
                    </th>
                  </tr>
                </thead>
                <tbody class="bg-white divide-y divide-gray-200">
                  <%= for message <- @messages do %>
                    <tr>
                      <td class="px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-900">
                        <%= message.order_id %>
                      </td>
                      <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                        <%= mask_phone(message.customer_phone) %>
                      </td>
                      <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                        <%= message.message_type %>
                      </td>
                      <td class="px-6 py-4 whitespace-nowrap">
                        <span class={"px-2 inline-flex text-xs leading-5 font-semibold rounded-full #{status_class(message.status)}"}>
                          <%= String.capitalize(message.status) %>
                        </span>
                      </td>
                      <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                        <%= format_datetime(message.sent_at) %>
                      </td>
                    </tr>
                  <% end %>

                  <%= if @messages == [] do %>
                    <tr>
                      <td colspan="5" class="px-6 py-4 text-center text-sm text-gray-500">
                        No messages yet. Messages will appear here when orders are created.
                      </td>
                    </tr>
                  <% end %>
                </tbody>
              </table>
            </div>
          </div>
        </div>
      <% end %>
    </div>
    """
  end

  # Private helpers

  defp status_class("pending"), do: "bg-yellow-100 text-yellow-800"
  defp status_class("sent"), do: "bg-blue-100 text-blue-800"
  defp status_class("delivered"), do: "bg-green-100 text-green-800"
  defp status_class("failed"), do: "bg-red-100 text-red-800"
  defp status_class(_), do: "bg-gray-100 text-gray-800"

  defp mask_phone(nil), do: "N/A"

  defp mask_phone(phone) do
    String.slice(phone, 0..2) <> "****" <> String.slice(phone, -4..-1)
  end

  defp format_datetime(nil), do: "N/A"

  defp format_datetime(datetime) do
    DateTime.to_string(datetime)
  end
end
