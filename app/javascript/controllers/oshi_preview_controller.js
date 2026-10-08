import { Controller } from "@hotwired/stimulus"

// 【推しの登録・編集画面の色のプレビュー】
// HTML では data-controller="oshi-preview" と書いて使う(form に付ける)
// アイコンの切り抜きは、グッズと共通の image_cropper_controller.js が担当する
export default class extends Controller {
  // HTML側で名札をつけた "color"(色の入力欄)、"bar"(色の帯)を受け取る
  static targets = ["color", "bar"]

  // 画面を開いたときにも、今の色で帯を塗る(入力ミスで画面が戻ってきたときのため)
  connect() {
    this.updateColor()
  }

  // 選んだ色 → 薄い色 → 白 のグラデーションで、帯を塗りなおす
  updateColor() {
    const color = this.colorTarget.value
    this.barTarget.style.backgroundImage = `linear-gradient(to right, ${color}, color-mix(in srgb, ${color} 20%, white), white)`
  }
}
