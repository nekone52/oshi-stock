import { Controller } from "@hotwired/stimulus"

// 【お知らせを自動で消す】
// HTML では data-controller="flash" と書いて使う
export default class extends Controller {
  // 画面に出たら、1.5秒後にふわっと消して(消えるまで0.5秒かかるので、見えているのは合計約2秒)、最後に取りのぞく
  connect() {
    this.timer = setTimeout(() => {
      this.element.classList.add("opacity-0")
      this.element.addEventListener("transitionend", () => this.element.remove(), { once: true })
    }, 1500)
  }

  // 1.5秒たつ前に別の画面へ移ったときは、タイマーを止める
  disconnect() {
    clearTimeout(this.timer)
  }
}
