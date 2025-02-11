import "phoenix_html"
import { Socket } from "phoenix"
import { LiveSocket } from "phoenix_live_view"
import DragAndDrop from "./hooks/drag_and_drop"
import DragOrder from "./hooks/drag_order"
import FloatingBar from "./hooks/floating_bar"
import SparkleEffect from "./hooks/sparkle_effect"
import DeleteBucket from "./hooks/delete_bucket"
import DragCard from "./hooks/drag_card"
import LocaleHook from "./hooks/locale"
import topbar from "../vendor/topbar"

let Hooks = {
  DragAndDrop,
  FloatingBar,  // Add FloatingBar to hooks
  UserToken: {
    mounted() {
      this.handleEvent("user-token", ({ token }) => {
        localStorage.setItem("user_token", token)
      })
    }
  },
  DragOrder: DragOrder,
  SparkleEffect: SparkleEffect,
  DragCard: DragCard,
  DeleteBucket: DeleteBucket,
  CopyToClipboard: {
    mounted() {
      window.addEventListener('clipboard-copied', () => {
        this.pushEvent("share_folder", {});
      });
    }
  },
  Locale: LocaleHook
}

function getCookie(name) {
  const value = `; ${document.cookie}`;
  const parts = value.split(`; ${name}=`);
  if (parts.length === 2) return parts.pop().split(';').shift();
}

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
let liveSocket = new LiveSocket("/live", Socket, {
  longPollFallbackMs: 2500,
  params: { _csrf_token: csrfToken, _visitor_name: getCookie("_visitor_name") },
  hooks: Hooks
})

window.copyToClipboard = async function (event, text) {
  event.preventDefault();
  try {
    const input = document.getElementById('share-url-input');
    if (input && input.value) {
      await navigator.clipboard.writeText(input.value);
      window.dispatchEvent(new CustomEvent('clipboard-copied'));
    }
  } catch (err) {
    console.error('Failed to copy text:', err);
  }
};

// Show progress bar on live navigation and form submits
topbar.config({ barColors: { 0: "#29d" }, shadowColor: "rgba(0, 0, 0, .3)" })
window.addEventListener("phx:page-loading-start", _info => topbar.show(300))
window.addEventListener("phx:page-loading-stop", _info => topbar.hide())

window.addEventListener("phx:set-cookie", (e) => {
  const { key, value, max_age } = e.detail;
  document.cookie = `${key}=${value};max-age=${max_age};path=/`;
});

window.addEventListener("phx:clear-cookie", (e) => {
  const { key } = e.detail;
  document.cookie = `${key}=; expires=Thu, 01 Jan 1970 00:00:00 GMT; path=/`;
});

window.addEventListener("phx:page-loading-stop", () => {
  const urlParams = new URLSearchParams(window.location.search);
  const locale = urlParams.get('locale');
  if (locale) {
    localStorage.setItem('locale', locale);
  }
});

// При загрузке страницы установить язык из localStorage
document.addEventListener("DOMContentLoaded", () => {
  const savedLocale = localStorage.getItem('locale');
  if (savedLocale && !window.location.search.includes('locale=')) {
    window.location.search = `?locale=${savedLocale}`;
  }
});

// connect if there are any LiveViews on the page
liveSocket.connect()

window.liveSocket = liveSocket
