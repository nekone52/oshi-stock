import { Controller } from "@hotwired/stimulus"

// 【推しの登録画面のプレビュー】
// HTML では data-controller="oshi-preview" と書いて使う
export default class extends Controller {
  // HTML側で名札をつけた "color"(色の入力欄)、"bar"(色の帯)、"image"(アイコンのプレビュー)、"placeholder"(画像を選ぶ前の絵)を受け取る
  static targets = ["color", "bar", "image", "placeholder"]

  // 画面を開いたときにも、今の色で帯を塗る(入力ミスで画面が戻ってきたときのため)
  connect() {
    this.updateColor()
  }

  // 選んだ色 → 薄い色 → 白 のグラデーションで、帯を塗りなおす
  updateColor() {
    const color = this.colorTarget.value
    this.barTarget.style.backgroundImage = `linear-gradient(to right, ${color}, color-mix(in srgb, ${color} 20%, white), white)`
  }

  // 選んだ画像を、丸い枠の中に表示する(まだ保存はしていない。見せるだけ)
  updateImage(event) {
    const file = event.target.files[0]
    if (!file) return

    this.imageTarget.src = URL.createObjectURL(file)
    this.imageTarget.classList.remove("hidden")
    this.placeholderTarget.classList.add("hidden")
  }
}
