import { Controller } from "@hotwired/stimulus"

// 【支払期限の大きいボタンと、推しストックの色のカレンダー】(#94)
// HTML では data-controller="deadline-picker" と書いて使う(ファイル名は _、HTML の名札は -)
// 本物の値は見えない入力(hidden_field)に「2026-10-14」の形で入れる。保存のしくみ(payment_deadline)は今までと同じ
const WEEKDAYS = ["日", "月", "火", "水", "木", "金", "土"]
const ONE_DAY = 86400000 // 1日のミリ秒(24時間 × 60分 × 60秒 × 1000)

export default class extends Controller {
  // HTML側で名札をつけたものを受け取る
  //   input:見えない本物の入力 / button:大きいボタン / panel:カレンダーを入れる場所
  //   text:「10月14日(水)」/ left:「あと3日」/ calMonth・calDay:ボタンの小さいカレンダーの絵
  static targets = ["input", "button", "panel", "text", "left", "calMonth", "calDay"]

  // 画面を開いたときにも、今の値でボタンの表示を作る(編集のときや、入力ミスで画面が戻ってきたときのため)
  connect() {
    this.render()
  }

  // 大きいボタン:押すたびに、カレンダーをひらく ⇔ とじる
  toggle() {
    if (this.panelTarget.hidden) {
      const picked = this.pickedDate()
      const base = picked || this.today()
      this.view = new Date(base.getFullYear(), base.getMonth(), 1)
      this.panelTarget.hidden = false
      this.buttonTarget.setAttribute("aria-expanded", "true")
      this.draw()
    } else {
      this.close()
    }
  }

  // 「<」「>」:前の月・次の月へ
  move({ params: { months } }) {
    this.view = new Date(this.view.getFullYear(), this.view.getMonth() + months, 1)
    this.draw()
  }

  // 日にちを押す:その日を入れて、カレンダーを閉じる
  pick({ params: { date } }) {
    this.inputTarget.value = date
    this.render()
    this.close()
  }

  // 「1週間後」「2週間後」:今日から〇日後を入れる
  addDays({ params: { days } }) {
    const date = this.today()
    date.setDate(date.getDate() + days)
    this.pick({ params: { date: this.iso(date) } })
  }

  // 「今月末」:来月の0日 = 今月の最後の日
  endOfMonth() {
    const today = this.today()
    this.pick({ params: { date: this.iso(new Date(today.getFullYear(), today.getMonth() + 1, 0)) } })
  }

  // 「期限なしにする」:空にする(保存すると、支払期限なしになる)
  clear() {
    this.pick({ params: { date: "" } })
  }

  // 見えない入力の値を見て、大きいボタンの表示を書きかえる
  render() {
    const date = this.pickedDate()
    if (!date) {
      this.textTarget.textContent = "期限なし"
      this.leftTarget.textContent = "押すとカレンダーがひらきます"
      this.leftTarget.classList.remove("font-bold", "text-unpaid")
      this.calMonthTarget.textContent = "—"
      this.calDayTarget.textContent = "?"
      return
    }

    const days = this.daysFromToday(date)
    // 今年なら「10月14日(水)」、ちがう年なら「2027年1月5日(火)」
    const yearLabel = date.getFullYear() === this.today().getFullYear() ? "" : `${date.getFullYear()}年`
    this.textTarget.textContent = `${yearLabel}${date.getMonth() + 1}月${date.getDate()}日(${WEEKDAYS[date.getDay()]})`
    this.leftTarget.textContent = days > 0 ? `あと${days}日` : days === 0 ? "今日まで" : `${-days}日すぎています`
    // 7日以内は、予約画面の「⚠ 期限が近い」と同じ色で目立たせる
    this.leftTarget.classList.toggle("font-bold", days <= 7)
    this.leftTarget.classList.toggle("text-unpaid", days <= 7)
    this.calMonthTarget.textContent = `${date.getMonth() + 1}月`
    this.calDayTarget.textContent = date.getDate()
  }

  // ---- ここから下は、この係の中だけで使う道具 ----

  close() {
    this.panelTarget.hidden = true
    this.buttonTarget.setAttribute("aria-expanded", "false")
  }

  // カレンダー(見出し・曜日・日にち・よく使う期限)を作って、panel に入れる
  // 今日 = ピンクの丸わく / 7日以内 = うすい茶色 / えらんだ日 = ピンクでぬりつぶし / 日曜 = ピンク・土曜 = 青
  draw() {
    const year = this.view.getFullYear()
    const month = this.view.getMonth()
    const firstWeekday = new Date(year, month, 1).getDay()
    const lastDay = new Date(year, month + 1, 0).getDate()
    const picked = this.pickedDate()

    const weekdays = WEEKDAYS.map((w, i) =>
      `<span class="py-0.5 text-center text-xs font-bold ${this.weekdayColor(i, "text-ink-soft")}">${w}</span>`
    ).join("")
    const blanks = "<span></span>".repeat(firstWeekday)
    let days = ""
    for (let d = 1; d <= lastDay; d++) {
      const date = new Date(year, month, d)
      const left = this.daysFromToday(date)
      const selected = picked && date.getTime() === picked.getTime()
      const classes = [
        "grid aspect-square min-h-11 w-full cursor-pointer place-items-center rounded-full font-display text-lg",
        selected ? "bg-accent text-white" : left < 0 ? "text-ink-faint" : this.weekdayColor(date.getDay(), "text-ink"),
        !selected && left >= 0 && left <= 7 ? "bg-unpaid-bg" : "",
        !selected && left === 0 ? "ring-2 ring-accent ring-inset" : ""
      ].join(" ")
      days += `<button type="button" class="${classes}" aria-pressed="${selected}" aria-label="${month + 1}月${d}日(${WEEKDAYS[date.getDay()]})"
        data-action="deadline-picker#pick" data-deadline-picker-date-param="${this.iso(date)}">${d}</button>`
    }

    const chip = "h-10 cursor-pointer rounded-full border border-line bg-white px-3.5 text-sm text-ink"
    const arrow = "grid h-11 w-11 cursor-pointer place-items-center rounded-full border border-line bg-white text-lg text-ink"
    this.panelTarget.innerHTML = `
      <div class="flex flex-col gap-2 rounded-2xl border-[1.5px] border-line bg-white px-2.5 pt-3 pb-3.5">
        <div class="flex items-center justify-between">
          <button type="button" class="${arrow}" aria-label="前の月" data-action="deadline-picker#move" data-deadline-picker-months-param="-1">&lt;</button>
          <b class="font-display text-[19px] text-ink">${year}年${month + 1}月</b>
          <button type="button" class="${arrow}" aria-label="次の月" data-action="deadline-picker#move" data-deadline-picker-months-param="1">&gt;</button>
        </div>
        <div class="grid grid-cols-7 gap-1">${weekdays}${blanks}${days}</div>
        <div class="flex flex-wrap gap-2.5 text-xs text-ink-soft">
          <span class="inline-flex items-center gap-1"><i class="h-3.5 w-3.5 rounded-full ring-2 ring-accent ring-inset"></i>今日</span>
          <span class="inline-flex items-center gap-1"><i class="h-3.5 w-3.5 rounded-full bg-unpaid-bg"></i>7日以内</span>
          <span class="inline-flex items-center gap-1"><i class="h-3.5 w-3.5 rounded-full bg-accent"></i>えらんだ日</span>
        </div>
        <div class="flex flex-wrap gap-1.5">
          <button type="button" class="${chip}" data-action="deadline-picker#addDays" data-deadline-picker-days-param="7">1週間後</button>
          <button type="button" class="${chip}" data-action="deadline-picker#addDays" data-deadline-picker-days-param="14">2週間後</button>
          <button type="button" class="${chip}" data-action="deadline-picker#endOfMonth">今月末</button>
        </div>
        <button type="button" class="w-fit cursor-pointer py-1.5 text-[13px] text-ink-soft underline" data-action="deadline-picker#clear">期限なしにする</button>
      </div>`
  }

  // 日曜はピンク、土曜は青、ほかはふつうの色
  weekdayColor(weekday, normal) {
    if (weekday === 0) return "text-accent-strong"
    if (weekday === 6) return "text-[#3F72B5]"
    return normal
  }

  // 見えない入力の「2026-10-14」を日付にする(空なら null)
  pickedDate() {
    const value = this.inputTarget.value
    if (!value) return null
    const [year, month, day] = value.split("-").map(Number)
    return new Date(year, month - 1, day)
  }

  // 日付を「2026-10-14」の形にする
  iso(date) {
    const pad = (n) => String(n).padStart(2, "0")
    return `${date.getFullYear()}-${pad(date.getMonth() + 1)}-${pad(date.getDate())}`
  }

  // 今日から何日後か(過ぎていたらマイナス)
  daysFromToday(date) {
    return Math.round((date - this.today()) / ONE_DAY)
  }

  // 今日の0時0分(「あと何日」を、時間のずれなしで数えるため)
  today() {
    const now = new Date()
    return new Date(now.getFullYear(), now.getMonth(), now.getDate())
  }
}
