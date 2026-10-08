import { Controller } from "@hotwired/stimulus"

// 【グッズの登録・編集フォーム】合計(単価 × 個数)の自動計算
// HTML では data-controller="item-form" と書いて使う(form に付ける)
// 商品画像の切り抜きは、推しのアイコンと共通の image_cropper_controller.js が担当する
export default class extends Controller {
  // HTML側で名札をつけたものを受け取る
  //   price:単価の入力欄 / quantity:個数の入力欄 / total:合計の表示
  static targets = ["price", "quantity", "total"]

  // 画面を開いたときにも、今の単価・個数で合計を出す(入力ミスで画面が戻ってきたときのため)
  connect() {
    this.updateTotal()
  }

  // 単価 × 個数 を計算して、「¥1,650」のようにカンマ区切りで表示する(空や数字でないときは 0 として計算)
  updateTotal() {
    const price = parseInt(this.priceTarget.value, 10) || 0
    const quantity = parseInt(this.quantityTarget.value, 10) || 0
    this.totalTarget.textContent = `¥${(price * quantity).toLocaleString("ja-JP")}`
  }
}
