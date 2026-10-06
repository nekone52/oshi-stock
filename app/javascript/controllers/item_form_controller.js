import { Controller } from "@hotwired/stimulus"

// 【グッズの登録フォーム】商品画像のプレビューと、合計(単価 × 個数)の自動計算
// HTML では data-controller="item-form" と書いて使う(form に付ける)
export default class extends Controller {
  // HTML側で名札をつけたものを受け取る
  //   image:選んだ画像のプレビュー / placeholder:画像を選ぶ前の絵
  //   price:単価の入力欄 / quantity:個数の入力欄 / total:合計の表示
  static targets = ["image", "placeholder", "price", "quantity", "total"]

  // 画面を開いたときにも、今の単価・個数で合計を出す(入力ミスで画面が戻ってきたときのため)
  connect() {
    this.updateTotal()
  }

  // 別の画面に移るときは、プレビュー用に作った URL を捨てる
  disconnect() {
    this.revokeImageUrl()
  }

  // 選んだ画像を、枠の中に表示する(まだ保存はしていない。見せるだけ)
  updateImage(event) {
    const file = event.target.files[0]
    if (!file) return

    this.revokeImageUrl()
    this.imageUrl = URL.createObjectURL(file)
    this.imageTarget.src = this.imageUrl
    this.imageTarget.classList.remove("hidden")
    this.placeholderTarget.classList.add("hidden")
  }

  // 単価 × 個数 を計算して、「¥1,650」のようにカンマ区切りで表示する(空や数字でないときは 0 として計算)
  updateTotal() {
    const price = parseInt(this.priceTarget.value, 10) || 0
    const quantity = parseInt(this.quantityTarget.value, 10) || 0
    this.totalTarget.textContent = `¥${(price * quantity).toLocaleString("ja-JP")}`
  }

  // プレビュー用に作った URL を捨てる(使い終わった URL を残さないため)
  revokeImageUrl() {
    if (this.imageUrl) URL.revokeObjectURL(this.imageUrl)
  }
}
