defmodule WishlistsWeb.LocaleSwitcherComponent do
  use WishlistsWeb, :live_component

  def render(assigns) do
    ~H"""
    <div class="flex space-x-2">
      <button
        phx-click="switch_locale"
        phx-value-locale="en"
        class={[
          "px-3 py-1 rounded-md text-white transition-colors",
          @locale == "en" && "bg-indigo-600",
          @locale != "en" && "bg-white/20 hover:bg-white/30"
        ]}
      >
        EN
      </button>
      <button
        phx-click="switch_locale"
        phx-value-locale="ru"
        class={[
          "px-3 py-1 rounded-md text-white transition-colors",
          @locale == "ru" && "bg-indigo-600",
          @locale != "ru" && "bg-white/20 hover:bg-white/30"
        ]}
      >
        RU
      </button>
    </div>
    """
  end
end
