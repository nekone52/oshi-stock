import { Controller } from "@hotwired/stimulus"

// 【お知らせを自動で消す】
// HTML では data-controller="flash" と書いて使う
export default class extends Controller {
  // 画面に出たら、2秒後にふわっと消して、最後に取りのぞく
  connect() {
    this.timer = setTimeout(() => {
      this.element.classList.add("opacity-0")
      this.element.addEventListener("transitionend", () => this.element.remove(), { once: true })
    }, 2000)
  }

  // 2秒たつ前に別の画面へ移ったときは、タイマーを止める
  disconnect() {
    clearTimeout(this.timer)
  }
}
