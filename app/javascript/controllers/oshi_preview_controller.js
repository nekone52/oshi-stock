import { Controller } from "@hotwired/stimulus"

// 【推しの登録・編集画面の色のプレビュー】
// HTML では data-controller="oshi-preview" と書いて使う(form に付ける)
// アイコンの切り抜きは、グッズと共通の image_cropper_controller.js が担当する
export default class extends Controller {
  // HTML側で名札をつけた "color"(色の入力欄)、"bar"(色の帯)、"swatch"(24色の丸)を受け取る
  static targets = ["color", "bar", "swatch"]

  // 画面を開いたときにも、今の色で帯を塗る(入力ミスで画面が戻ってきたときのため)
  connect() {
    this.updateColor()
  }

  // 24色の丸を押したとき、その色をカラーピッカーに入れる
  pick(event) {
    this.colorTarget.value = event.currentTarget.dataset.color
    this.updateColor()
  }

  // 選んだ色 → 薄い色 → 白 のグラデーションで、帯を塗りなおす。選ばれている丸に印をつける
  updateColor() {
    const color = this.colorTarget.value
    this.barTarget.style.backgroundImage = `linear-gradient(to right, ${color}, color-mix(in srgb, ${color} 20%, white), white)`
    this.swatchTargets.forEach((swatch) => {
      swatch.setAttribute("aria-pressed", swatch.dataset.color.toUpperCase() === color.toUpperCase())
    })
  }
}
