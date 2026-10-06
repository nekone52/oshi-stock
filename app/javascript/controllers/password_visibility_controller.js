import { Controller } from "@hotwired/stimulus"

// 【パスワードの表示・非表示の切り替え】
// HTML では data-controller="password-visibility" と書いて使う
export default class extends Controller {
  // HTML側で名札をつけた "input"(入力欄)、"showIcon"(目)、"hideIcon"(斜線の目)を受け取る
  static targets = ["input", "showIcon", "hideIcon"]

  toggle(event) {
    // 現在伏字(password)なら文字(text)に、文字なら伏字に戻す
    const isPassword = this.inputTarget.type === "password"
    this.inputTarget.type = isPassword ? "text" : "password"

    // アイコンを入れ替える(伏字のときは目、文字が見えているときは斜線の目)
    this.showIconTarget.classList.toggle("hidden", isPassword)
    this.hideIconTarget.classList.toggle("hidden", !isPassword)

    // 画面読み上げを使う人にも、今の状態を伝える
    event.currentTarget.setAttribute("aria-label", isPassword ? "パスワードを隠す" : "パスワードを表示する")
  }
}
