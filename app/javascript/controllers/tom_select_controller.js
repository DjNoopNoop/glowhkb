import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    const TS = (typeof window !== "undefined" && window.TomSelect) || (typeof globalThis !== "undefined" && globalThis.TomSelect)
    console.log("[tom-select] connect", { element: this.element, optionsLength: this.element.options?.length, TomSelect: TS })

    if (!TS) {
      console.error("[tom-select] TomSelect not found on window; ensure the UMD bundle is loaded before controllers.")
      return
    }

    try {
      new TS(this.element, {
        plugins: ["remove_button"],
        create: true,
        persist: false
      })
      console.log("[tom-select] initialized")
    } catch (err) {
      console.error("[tom-select] init error", err)
    }
  }
}