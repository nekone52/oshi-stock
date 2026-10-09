import { Controller } from "@hotwired/stimulus"

// 【テーマの色えらび】設定画面の「推しの色(おすすめ)」とカラーピッカー
// ・丸い色を押すと、その色がカラーピッカーに入る(保存は「保存する」ボタンで)
// ・選んだ色で、フォームの中のプレビューとボタンの見え方を、保存する前に変えて見せる
// 色の計算は app/helpers/theme_helper.rb とそろえている
export default class extends Controller {
  static targets = ["input", "swatch"]

  connect() {
    this.sync()
  }

  // 丸い色を押したとき
  pick(event) {
    this.inputTarget.value = event.currentTarget.dataset.color
    this.sync()
  }

  // 今の色で、プレビューの色と、選ばれている丸の印をそろえる
  sync() {
    const color = this.inputTarget.value.toUpperCase()
    const base = this.hexToRgb(color)
    const white = [255, 255, 255]
    const ink = [43, 30, 42] // 文字の黒(--color-ink)

    // このフォームの中だけ、色の入れ物を上書きする(保存するまで、ほかの画面は変わらない)
    const style = this.element.style
    style.setProperty("--color-accent", color)
    style.setProperty("--color-accent-strong", this.rgbToHex(this.mix(base, ink, 0.35)))
    style.setProperty("--color-accent-soft", this.rgbToHex(this.mix(base, white, 0.82)))
    style.setProperty("--color-on-accent", this.contrast(base, white) >= 3 ? "#FFFFFF" : "#2B1E2A")

    // 選ばれている丸に印をつける(読み上げにも「選択中」と伝わる)
    this.swatchTargets.forEach((swatch) => {
      swatch.setAttribute("aria-pressed", swatch.dataset.color.toUpperCase() === color)
    })
  }

  // "#E8577A" → [232, 87, 122]
  hexToRgb(hex) {
    return [1, 3, 5].map((i) => parseInt(hex.slice(i, i + 2), 16))
  }

  // [232, 87, 122] → "#E8577A"
  rgbToHex(rgb) {
    return "#" + rgb.map((v) => Math.round(Math.min(255, Math.max(0, v))).toString(16).padStart(2, "0")).join("").toUpperCase()
  }

  // 2つの色を、rate の割合でまぜる
  mix(a, b, rate) {
    return a.map((v, i) => v * (1 - rate) + b[i] * rate)
  }

  // 色の明るさ(0 = 黒 〜 1 = 白)
  luminance(rgb) {
    const [r, g, b] = rgb.map((v) => {
      v /= 255
      return v <= 0.03928 ? v / 12.92 : Math.pow((v + 0.055) / 1.055, 2.4)
    })
    return 0.2126 * r + 0.7152 * g + 0.0722 * b
  }

  // 2つの色の見分けやすさ(1 = 同じ 〜 21 = 白と黒)
  contrast(a, b) {
    const [lighter, darker] = [this.luminance(a), this.luminance(b)].sort((x, y) => y - x)
    return (lighter + 0.05) / (darker + 0.05)
  }
}
