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
import ImageLoader from "./hooks/image_loader"
import ScrollAnimation from "./hooks/scroll_animation"
import topbar from "../vendor/topbar"
import HideableHeader from "./hooks/header"

let Hooks = {
  DragAndDrop,
  FloatingBar,
  UserToken: {
    mounted() {
      this.handleEvent("user-token", ({ token }) => {
        localStorage.setItem("user_token", token)
      })
    }
  },
  DragOrder,
  SparkleEffect,
  DragCard,
  DeleteBucket,
  ImageLoader,
  CopyToClipboard: {
    mounted() {
      window.addEventListener('clipboard-copied', () => {
        this.pushEvent("copied_to_clipboard", {});
      });
    }
  },
  Locale: LocaleHook,
  ScrollAnimation,
  HideableHeader
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

window.addEventListener("phx:reinitialize_drag", () => {
  requestAnimationFrame(() => {
    document.querySelectorAll('[data-card-id]').forEach(card => {
      if (card._dragCard) {
        card._dragCard.initializeDrag();
      }
    });
  });
});

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

window.addEventListener("phx:init_new_card", () => {
  setTimeout(() => {
    document.querySelectorAll('[data-card-id]').forEach(cardElement => {
      const hookContext = {
        el: cardElement,
        pushEvent: (event, payload) => {
          liveSocket.pushEvent(event, payload, cardElement);
        }
      };

      if (DragCard.mounted) {
        DragCard.mounted.call(hookContext);
      }
    });

    const foldersContainer = document.getElementById('folders-container');
    if (foldersContainer) {
      const hookContext = {
        el: foldersContainer,
        pushEvent: (event, payload) => {
          liveSocket.pushEvent(event, payload, foldersContainer);
        }
      };

      if (DragAndDrop.mounted) {
        DragAndDrop.mounted.call(hookContext);
      }
    }
  }, 100);
});

document.addEventListener("DOMContentLoaded", () => {
  const savedLocale = localStorage.getItem('locale');
  if (savedLocale && !window.location.search.includes('locale=')) {
    window.location.search = `?locale=${savedLocale}`;
  }
});

liveSocket.connect()

window.liveSocket = liveSocket
