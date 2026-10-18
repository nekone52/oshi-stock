import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["color", "bar", "swatch"]

  connect() {
    this.updateColor()
  }

  pick(event) {
    this.colorTarget.value = event.currentTarget.dataset.color
    this.updateColor()
  }

  updateColor() {
    const color = this.colorTarget.value
    this.barTarget.style.backgroundImage = `linear-gradient(to right, ${color}, color-mix(in srgb, ${color} 20%, white), white)`
    this.swatchTargets.forEach((swatch) => {
      swatch.setAttribute("aria-pressed", swatch.dataset.color.toUpperCase() === color.toUpperCase())
    })
  }
}
