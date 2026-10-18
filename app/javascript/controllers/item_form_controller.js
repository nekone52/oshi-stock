import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["price", "quantity", "total", "goalSwitch", "goalField", "goalInput"]

  connect() {
    this.updateTotal()
    if (this.hasGoalSwitchTarget) {
      this.goalSwitchTarget.checked = this.goalInputTarget.value !== ""
      this.showGoal()
    }
  }

  toggleGoal() {
    if (!this.goalSwitchTarget.checked) this.goalInputTarget.value = ""
    this.showGoal()
  }

  showGoal() {
    this.goalFieldTarget.hidden = !this.goalSwitchTarget.checked
  }

  updateTotal() {
    const price = parseInt(this.priceTarget.value, 10) || 0
    const quantity = parseInt(this.quantityTarget.value, 10) || 0
    this.totalTarget.textContent = `¥${(price * quantity).toLocaleString("ja-JP")}`
  }
}
