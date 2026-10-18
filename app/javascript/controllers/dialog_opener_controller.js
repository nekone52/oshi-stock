import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { id: String }

  open() {
    document.getElementById(this.idValue)?.showModal()
  }
}
