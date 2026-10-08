import { Controller } from "@hotwired/stimulus"

// 【ダイアログ(シート)を開く・閉じる】
// HTML では <dialog data-controller="dialog"> と書いて使う
// 開くボタンは dialog の外にあるときは、dialog_opener_controller.js を使う
export default class extends Controller {
  // シートを開く(画面の上に重ねて、後ろは押せなくなる)
  open() {
    this.element.showModal()
  }

  // シートを閉じる
  close() {
    this.element.close()
  }

  // シートの外側(うす暗いところ)を押したら閉じる
  closeOnBackdrop(event) {
    if (event.target === this.element) this.close()
  }

  // カテゴリを追加できたら、入力欄を空にする(うまくいかなかったときは、直せるように残す)
  resetForm(event) {
    if (event.detail.success) event.target.reset()
  }
}
