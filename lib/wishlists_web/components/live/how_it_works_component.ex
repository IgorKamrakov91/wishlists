defmodule WishlistsWeb.HowItWorksComponent do
  use WishlistsWeb, :live_component

  def render(assigns) do
    ~H"""
    <section
      class="relative min-h-screen bg-black overflow-x-hidden"
      id="how-it-works-section"
      phx-hook="ScrollAnimation"
    >
      <div class="md:sticky md:top-0 min-h-screen flex items-center justify-center py-16 md:py-0">
        <div class="absolute inset-0 bg-gradient-to-b from-gray-900 to-black opacity-90"></div>

        <div class="container mx-auto px-4 relative z-10">
          <div
            class="text-center mb-8 md:mb-16 opacity-0 transform translate-y-8 transition-all duration-1000"
            data-scroll-element="title"
          >
            <h2 class="text-4xl md:text-6xl font-bold bg-gradient-to-r from-white to-gray-300 bg-clip-text text-transparent">
              {@translations["how_it_works"]}
            </h2>
          </div>

          <div class="grid grid-cols-1 md:grid-cols-3 gap-6 md:gap-12 max-w-7xl mx-auto">
            <div
              class="relative opacity-0 transform translate-y-16 transition-all duration-1000"
              data-scroll-element="step-1"
            >
              <div class="bg-gray-900/50 backdrop-blur-lg rounded-2xl md:rounded-3xl p-6 md:p-8 border border-gray-800">
                <div class="w-16 h-16 md:w-24 md:h-24 bg-gradient-to-br from-indigo-500 to-purple-600 rounded-full flex items-center justify-center mx-auto mb-6 md:mb-8 transform transition-transform duration-500">
                  <svg
                    class="w-8 h-8 md:w-12 md:h-12 text-white"
                    fill="none"
                    stroke="currentColor"
                    viewBox="0 0 24 24"
                  >
                    <path
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      stroke-width="2"
                      d="M12 6v6m0 0v6m0-6h6m-6 0H6"
                    >
                    </path>
                  </svg>
                </div>
                <h3 class="text-xl md:text-2xl font-semibold text-center mb-3 md:mb-4 text-white">
                  {@translations["create_wishlist"]}
                </h3>
                <p class="text-gray-300 text-center text-base md:text-lg leading-relaxed">
                  {@translations["create_wishlist_description"]}
                </p>
              </div>
            </div>

            <div
              class="relative opacity-0 transform translate-y-16 transition-all duration-1000 delay-200"
              data-scroll-element="step-2"
            >
              <div class="bg-gray-900/50 backdrop-blur-lg rounded-2xl md:rounded-3xl p-6 md:p-8 border border-gray-800">
                <div class="w-16 h-16 md:w-24 md:h-24 bg-gradient-to-br from-purple-500 to-pink-600 rounded-full flex items-center justify-center mx-auto mb-6 md:mb-8 transform transition-transform duration-500">
                  <svg
                    class="w-8 h-8 md:w-12 md:h-12 text-white"
                    fill="none"
                    stroke="currentColor"
                    viewBox="0 0 24 24"
                  >
                    <path
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      stroke-width="2"
                      d="M8.684 13.342C8.886 12.938 9 12.482 9 12c0-.482-.114-.938-.316-1.342m0 2.684a3 3 0 110-2.684m0 2.684l6.632 3.316m-6.632-6l6.632-3.316m0 0a3 3 0 105.367-2.684 3 3 0 00-5.367 2.684zm0 9.316a3 3 0 105.368 2.684 3 3 0 00-5.368-2.684z"
                    >
                    </path>
                  </svg>
                </div>
                <h3 class="text-xl md:text-2xl font-semibold text-center mb-3 md:mb-4 text-white">
                  {@translations["share_with_friends"]}
                </h3>
                <p class="text-gray-300 text-center text-base md:text-lg leading-relaxed">
                  {@translations["share_with_friends_description"]}
                </p>
              </div>
            </div>

            <div
              class="relative opacity-0 transform translate-y-16 transition-all duration-1000 delay-400"
              data-scroll-element="step-3"
            >
              <div class="bg-gray-900/50 backdrop-blur-lg rounded-2xl md:rounded-3xl p-6 md:p-8 border border-gray-800">
                <div class="w-16 h-16 md:w-24 md:h-24 bg-gradient-to-br from-pink-500 to-rose-600 rounded-full flex items-center justify-center mx-auto mb-6 md:mb-8 transform transition-transform duration-500">
                  <svg
                    class="w-8 h-8 md:w-12 md:h-12 text-white"
                    fill="none"
                    stroke="currentColor"
                    viewBox="0 0 24 24"
                  >
                    <path
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      stroke-width="2"
                      d="M12 8v13m0-13V6a2 2 0 112 2h-2zm0 0V5.5A2.5 2.5 0 109.5 8H12zm-7 4h14M5 12a2 2 0 110-4h14a2 2 0 110 4M5 12v7a2 2 0 002 2h10a2 2 0 002-2v-7"
                    >
                    </path>
                  </svg>
                </div>
                <h3 class="text-xl md:text-2xl font-semibold text-center mb-3 md:mb-4 text-white">
                  {@translations["receive_gifts"]}
                </h3>
                <p class="text-gray-300 text-center text-base md:text-lg leading-relaxed">
                  {@translations["receive_gifts_description"]}
                </p>
              </div>
            </div>
          </div>

          <div
            class="mt-8 md:mt-16 text-center opacity-0 transform translate-y-8 transition-all duration-1000 delay-600"
            data-scroll-element="cta"
          >
            <button
              type="button"
              phx-click="open_auth_modal"
              class="inline-flex items-center px-6 md:px-8 py-3 md:py-4 text-base md:text-lg font-semibold rounded-md bg-gradient-to-r from-indigo-600 to-purple-600 text-white shadow-lg hover:shadow-xl focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-indigo-600 transition-all duration-300 ease-in-out transform hover:scale-105 hover:from-indigo-500 hover:to-purple-500 relative group"
            >
              <div class="absolute inset-0 rounded-md bg-white/20 opacity-0 group-hover:opacity-100 transition-opacity duration-300">
              </div>
              <div class="absolute -inset-1 rounded-md bg-gradient-to-r from-indigo-400 to-purple-400 opacity-20 blur-lg group-hover:opacity-30 transition-opacity duration-300">
              </div>
              {@translations["try_it_now"]}
              <svg
                class="ml-2 -mr-1 h-5 w-5 md:h-6 md:w-6"
                fill="none"
                stroke="currentColor"
                viewBox="0 0 24 24"
              >
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M14 5l7 7m0 0l-7 7m7-7H3"
                >
                </path>
              </svg>
            </button>
          </div>
        </div>
      </div>
    </section>
    """
  end
end
