import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.timer = setTimeout(() => {
      this.element.classList.add("opacity-0")
      this.element.addEventListener("transitionend", () => this.element.remove(), { once: true })
    }, 1500)
  }

  disconnect() {
    clearTimeout(this.timer)
  }
}
