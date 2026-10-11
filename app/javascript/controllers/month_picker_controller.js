import { Controller } from "@hotwired/stimulus"

// 【発売月の大きいボタンと、12か月のボタン】(#94)
// HTML では data-controller="month-picker" と書いて使う(ファイル名は _、HTML の名札は -)
// 本物の値は見えない入力(hidden_field)に「2026-11-01」の形で入れる(日は1日。保存のしくみ release_month は今までと同じ)
// 選べるのは、前の年から2年先まで(前のリストの「1年前から2年先まで」とだいたい同じ)

export default class extends Controller {
  // HTML側で名札をつけたものを受け取る
  //   input:見えない本物の入力 / button:大きいボタン / panel:月のボタンを入れる場所
  //   text:「2026年11月」/ calTop・calBottom:ボタンの小さいカレンダーの絵(上に年、下に月)
  static targets = ["input", "button", "panel", "text", "calTop", "calBottom"]

  connect() {
    this.render()
  }

  // 大きいボタン:押すたびに、月のボタンをひらく ⇔ とじる
  toggle() {
    if (this.panelTarget.hidden) {
      const picked = this.picked()
      this.year = picked ? picked.year : this.thisYear()
      this.panelTarget.hidden = false
      this.buttonTarget.setAttribute("aria-expanded", "true")
      this.draw()
    } else {
      this.close()
    }
  }

  // 「<」「>」:前の年・次の年へ(はしまで来たら、それ以上は行かない)
  move({ params: { years } }) {
    this.year = Math.min(Math.max(this.year + years, this.thisYear() - 1), this.thisYear() + 2)
    this.draw()
  }

  // 月を押す:その月を入れて閉じる。「未定」は空にする
  pick({ params: { value } }) {
    this.inputTarget.value = value
    this.render()
    this.close()
  }

  // 見えない入力の値を見て、大きいボタンの表示を書きかえる
  render() {
    const picked = this.picked()
    this.textTarget.textContent = picked ? `${picked.year}年${picked.month}月` : "未定"
    this.calTopTarget.textContent = picked ? picked.year : "—"
    this.calBottomTarget.textContent = picked ? `${picked.month}月` : "?"
  }

  // ---- ここから下は、この係の中だけで使う道具 ----

  close() {
    this.panelTarget.hidden = true
    this.buttonTarget.setAttribute("aria-expanded", "false")
  }

  // 「< 2026年 >」と、12か月のボタン(4列 × 3段)と「未定」を作って、panel に入れる
  // 今月 = 点線のわく / えらんだ月 = ピンクでぬりつぶし
  draw() {
    const picked = this.picked()
    const now = new Date()
    let months = ""
    for (let m = 1; m <= 12; m++) {
      const selected = picked && picked.year === this.year && picked.month === m
      const thisMonth = this.year === now.getFullYear() && m === now.getMonth() + 1
      const classes = [
        "min-h-11 cursor-pointer rounded-xl border font-display text-base",
        selected ? "border-accent bg-accent text-white" : "bg-white text-ink",
        !selected && thisMonth ? "border-dashed border-ink-faint" : "",
        !selected && !thisMonth ? "border-line" : ""
      ].join(" ")
      months += `<button type="button" class="${classes}" aria-pressed="${!!selected}"
        data-action="month-picker#pick" data-month-picker-value-param="${this.year}-${String(m).padStart(2, "0")}-01">${m}月</button>`
    }

    const undecided = !picked
    const arrow = "grid h-11 w-11 cursor-pointer place-items-center rounded-full border border-line bg-white text-lg text-ink disabled:cursor-default disabled:opacity-30"
    this.panelTarget.innerHTML = `
      <div class="flex flex-col gap-2.5 rounded-2xl border-[1.5px] border-line bg-white px-2.5 pt-3 pb-3.5">
        <div class="flex items-center justify-between">
          <button type="button" class="${arrow}" aria-label="前の年" data-action="month-picker#move" data-month-picker-years-param="-1" ${this.year <= this.thisYear() - 1 ? "disabled" : ""}>&lt;</button>
          <b class="font-display text-[19px] text-ink">${this.year}年</b>
          <button type="button" class="${arrow}" aria-label="次の年" data-action="month-picker#move" data-month-picker-years-param="1" ${this.year >= this.thisYear() + 2 ? "disabled" : ""}>&gt;</button>
        </div>
        <div class="grid grid-cols-4 gap-1.5">
          ${months}
          <button type="button" class="col-span-4 min-h-11 cursor-pointer rounded-xl border font-display text-base ${undecided ? "border-accent bg-accent text-white" : "border-line bg-white text-ink"}"
            aria-pressed="${undecided}" data-action="month-picker#pick" data-month-picker-value-param="">未定</button>
        </div>
        <p class="text-xs text-ink-soft">点線のわくが今月です</p>
      </div>`
  }

  // 見えない入力の「2026-11-01」を { year: 2026, month: 11 } にする(空なら null)
  picked() {
    const value = this.inputTarget.value
    if (!value) return null
    const [year, month] = value.split("-").map(Number)
    return { year, month }
  }

  thisYear() {
    return new Date().getFullYear()
  }
}
