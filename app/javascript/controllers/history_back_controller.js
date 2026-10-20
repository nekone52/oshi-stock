import { Controller } from "@hotwired/stimulus"

// 「<」をブラウザの戻ると同じ動きにする(新規登録の入力を消さないため)
export default class extends Controller {
  back(event) {
    // 同じアプリの画面から来たときだけ、ひとつ前にもどる
    // URL を直接開いたときなどは、ふつうのリンク(href)のまま進む
    const cameFromThisApp = document.referrer.startsWith(window.location.origin)
    if (!cameFromThisApp || window.history.length <= 1) return

    event.preventDefault()
    window.history.back()
  }
}
