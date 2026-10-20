import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["price", "quantity", "total", "goalSwitch", "goalField", "goalInput", "reservationFields"]

  connect() {
    this.updateTotal()
    if (this.hasGoalSwitchTarget) {
      this.goalSwitchTarget.checked = this.goalInputTarget.value !== ""
      this.showGoal()
    }
    this.showReservation()
  }

  // 予約開始日・〆切は「ほしい物」のときだけ出す(ほかの状態にしても、入れた日付は消さない)
  showReservation() {
    if (!this.hasReservationFieldsTarget) return
    const wanted = this.element.querySelector("input[name='item[status]'][value='wanted']")
    this.reservationFieldsTarget.hidden = !wanted?.checked
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
