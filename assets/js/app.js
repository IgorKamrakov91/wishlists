import "phoenix_html"
import { Socket } from "phoenix"
import { LiveSocket } from "phoenix_live_view"
import DragAndDrop from "./hooks/drag_and_drop"
import DragOrder from "./hooks/drag_order"
import FloatingBar from "./hooks/floating_bar"
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
  DragOrder: DragOrder
}

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
let liveSocket = new LiveSocket("/live", Socket, {
  longPollFallbackMs: 2500,
  params: { _csrf_token: csrfToken },
  hooks: Hooks
})

// Show progress bar on live navigation and form submits
topbar.config({ barColors: { 0: "#29d" }, shadowColor: "rgba(0, 0, 0, .3)" })
window.addEventListener("phx:page-loading-start", _info => topbar.show(300))
window.addEventListener("phx:page-loading-stop", _info => topbar.hide())

// connect if there are any LiveViews on the page
liveSocket.connect()

window.liveSocket = liveSocket
