defmodule ShopifyWhatsappWeb.DashboardLayout do
  @moduledoc """
  Shared layout component for authenticated dashboard pages.
  Renders a header with shop domain as primary identity, tab navigation,
  logout link, flash messages, and a11y landmarks.
  """
  use Phoenix.Component

  use ShopifyWhatsappWeb, :verified_routes

  alias Phoenix.LiveView.JS

  attr :current_shop, :map, required: true
  attr :active_tab, :string, required: true, values: ["dashboard", "settings"]
  attr :flash, :map, default: %{}
  slot :inner_block, required: true

  def dashboard_layout(assigns) do
    ~H"""
    <div class="min-h-screen bg-gray-50">
      <!-- Skip to content link for keyboard navigation -->
      <a
        href="#main-content"
        class="sr-only focus:not-sr-only focus:absolute focus:z-50 focus:top-2 focus:left-2 focus:px-4 focus:py-2 focus:bg-white focus:ring-2 focus:ring-green-500 focus:text-gray-900 focus:rounded-md"
      >
        Skip to content
      </a>

      <header class="bg-white shadow">
        <div class="max-w-7xl mx-auto px-4 py-4 sm:px-6 lg:px-8">
          <div class="flex justify-between items-center">
            <div>
              <h1 class="text-2xl font-bold text-gray-900"><%= @current_shop.shop_domain %></h1>
              <p class="mt-1 text-sm text-gray-500">WhatsApp Notifications</p>
            </div>
            <.link
              href="/logout"
              method="delete"
              class="px-4 py-2 text-sm text-gray-600 hover:text-gray-900 border border-gray-300 rounded-md hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-green-500"
            >
              Logout
            </.link>
          </div>
          <nav class="mt-4 -mb-px flex space-x-8" aria-label="Dashboard navigation">
            <.link
              href="/dashboard"
              class={
                if @active_tab == "dashboard",
                  do: "border-green-500 text-green-700 whitespace-nowrap py-2 px-1 border-b-2 font-medium text-sm",
                  else: "border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300 whitespace-nowrap py-2 px-1 border-b-2 font-medium text-sm focus:outline-none focus:text-green-700 focus:border-green-500"
              }
            >
              Dashboard
            </.link>
            <.link
              href="/dashboard/settings"
              class={
                if @active_tab == "settings",
                  do: "border-green-500 text-green-700 whitespace-nowrap py-2 px-1 border-b-2 font-medium text-sm",
                  else: "border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300 whitespace-nowrap py-2 px-1 border-b-2 font-medium text-sm focus:outline-none focus:text-green-700 focus:border-green-500"
              }
            >
              Settings
            </.link>
          </nav>
        </div>
      </header>

      <!-- Flash messages -->
      <%= if msg = Phoenix.Flash.get(@flash, :info) do %>
        <div
          id="flash-info"
          phx-click={JS.push("lv:clear-flash", value: %{key: :info})}
          data-clear
          role="alert"
          class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 mt-4"
        >
          <div class="rounded-lg bg-green-50 border border-green-200 p-4">
            <div class="flex">
              <svg class="h-5 w-5 text-green-400 flex-shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
              </svg>
              <div class="ml-3">
                <p class="text-sm font-medium text-green-800"><%= msg %></p>
              </div>
            </div>
          </div>
        </div>
      <% end %>

      <%= if msg = Phoenix.Flash.get(@flash, :error) do %>
        <div
          id="flash-error"
          phx-click={JS.push("lv:clear-flash", value: %{key: :error})}
          role="alert"
          class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 mt-4"
        >
          <div class="rounded-lg bg-red-50 border border-red-200 p-4">
            <div class="flex">
              <svg class="h-5 w-5 text-red-400 flex-shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
              </svg>
              <div class="ml-3">
                <p class="text-sm font-medium text-red-800"><%= msg %></p>
              </div>
            </div>
          </div>
        </div>
      <% end %>

      <main id="main-content">
        <%= render_slot(@inner_block) %>
      </main>
    </div>
    """
  end
end
