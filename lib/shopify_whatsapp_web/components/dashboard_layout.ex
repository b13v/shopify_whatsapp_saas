defmodule ShopifyWhatsappWeb.DashboardLayout do
  @moduledoc """
  Shared layout component for authenticated dashboard pages.
  Renders a header with shop domain, tab navigation, and logout link.
  """
  use Phoenix.Component

  use ShopifyWhatsappWeb, :verified_routes

  attr :current_shop, :map, required: true
  attr :active_tab, :string, required: true, values: ["dashboard", "settings"]
  slot :inner_block, required: true

  def dashboard_layout(assigns) do
    ~H"""
    <div class="min-h-screen bg-gray-50">
      <header class="bg-white shadow">
        <div class="max-w-7xl mx-auto px-4 py-4 sm:px-6 lg:px-8">
          <div class="flex justify-between items-center">
            <div>
              <h1 class="text-2xl font-bold text-gray-900">WhatsApp Notifications</h1>
              <p class="mt-1 text-sm text-gray-500"><%= @current_shop.shop_domain %></p>
            </div>
            <.link
              href="/logout"
              method="delete"
              class="px-4 py-2 text-sm text-gray-600 hover:text-gray-900 border border-gray-300 rounded-md hover:bg-gray-50"
            >
              Logout
            </.link>
          </div>
          <nav class="mt-4 -mb-px flex space-x-8">
            <.link
              href="/dashboard"
              class={
                if @active_tab == "dashboard",
                  do: "border-blue-500 text-blue-600 whitespace-nowrap py-2 px-1 border-b-2 font-medium text-sm",
                  else: "border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300 whitespace-nowrap py-2 px-1 border-b-2 font-medium text-sm"
              }
            >
              Dashboard
            </.link>
            <.link
              href="/dashboard/settings"
              class={
                if @active_tab == "settings",
                  do: "border-blue-500 text-blue-600 whitespace-nowrap py-2 px-1 border-b-2 font-medium text-sm",
                  else: "border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300 whitespace-nowrap py-2 px-1 border-b-2 font-medium text-sm"
              }
            >
              Settings
            </.link>
          </nav>
        </div>
      </header>

      <%= render_slot(@inner_block) %>
    </div>
    """
  end
end
