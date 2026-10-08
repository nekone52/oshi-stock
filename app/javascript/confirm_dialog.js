import { Turbo } from "@hotwired/turbo-rails"

// 【確認ダイアログを、アプリの見た目に差しかえる】
// data-turbo-confirm を付けたボタン(グッズ・カテゴリの消去など)を押したときに、
// ブラウザの標準の確認ダイアログの代わりに、レイアウトの <dialog id="confirm_dialog"> を出す
// 「消去する」を押したら true、「やめる」・外側を押したら false を返す(Turbo がそれを見て、送るかやめるか決める)
Turbo.config.forms.confirm = (message) => {
  const dialog = document.getElementById("confirm_dialog")
  // もしダイアログが見つからなければ、ブラウザの標準の確認ダイアログを使う
  if (!dialog) return Promise.resolve(window.confirm(message))

  // 何を消去するかのメッセージを、絵の下に表示する
  dialog.querySelector("[data-confirm-message]").textContent = message
  // 前に押したボタンの答えが残らないように、空にしてから開く
  dialog.returnValue = ""
  dialog.showModal()

  return new Promise((resolve) => {
    // ダイアログが閉じたら、押されたボタンの答え(returnValue)で決める
    dialog.addEventListener("close", () => resolve(dialog.returnValue === "confirm"), { once: true })
  })
}
