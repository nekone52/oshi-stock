import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  open() {
    this.element.showModal()
  }

  close() {
    this.element.close()
  }

  closeOnBackdrop(event) {
    if (event.target === this.element) this.close()
  }

  resetForm(event) {
    if (event.detail.success) event.target.reset()
  }
}
