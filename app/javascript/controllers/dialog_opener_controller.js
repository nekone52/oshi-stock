import { Controller } from "@hotwired/stimulus"

// 【ダイアログ(シート)を開くボタン】
// HTML では data-controller="dialog-opener" data-dialog-opener-id-value="開きたい dialog の id" と書いて使う
// 開きたい dialog が、ボタンとはなれた場所(フォームの外)にあるので、id で探して開く
export default class extends Controller {
  static values = { id: String }

  open() {
    document.getElementById(this.idValue)?.showModal()
  }
}
