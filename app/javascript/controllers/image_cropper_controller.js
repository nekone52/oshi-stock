import { Controller } from "@hotwired/stimulus"
import Cropper from "cropperjs"

// 【画像の切り抜き(推しのアイコン・グッズの商品画像で共通)】
// HTML では、画像を選ぶ欄と切り抜きの場所をまとめた部分に data-controller="image-cropper" と書いて使う
// 切り抜く形は values で決める
//   aspect:縦横の比率(推しのアイコン 8/11 = 名刺と同じ縦長、グッズ 1 = 正方形)
//   width / height:保存する画像の大きさ(px)
export default class extends Controller {
  static values = { aspect: Number, width: Number, height: Number }

  // HTML側で名札をつけたものを受け取る
  //   fileInput:画像を選ぶ欄 / cropArea:切り抜きの場所 / cropImage:切り抜く画像 / zoom:拡大縮小のスライダー
  //   preview:切り抜いた結果のプレビュー / image:今の画像(保存ずみ) / placeholder:画像を選ぶ前の絵
  static targets = ["fileInput", "cropArea", "cropImage", "zoom", "preview", "image", "placeholder"]

  // 「登録する」「保存する」を押したときに、切り抜いた画像に差しかえるため、フォームの送信を見張る
  connect() {
    this.form = this.element.closest("form")
    this.submitHandler = this.submit.bind(this)
    this.form?.addEventListener("submit", this.submitHandler)
  }

  // 別の画面に移るときは、見張りと切り抜きの道具を片付ける
  disconnect() {
    this.form?.removeEventListener("submit", this.submitHandler)
    this.destroyCropper()
  }

  // 画像を選んだら、切り抜きの場所に出す(まだ保存はしていない)
  choose(event) {
    const file = event.target.files[0]
    if (!file) return

    this.destroyCropper()
    this.fileType = file.type
    this.cropped = false
    this.cropImageTarget.src = URL.createObjectURL(file)
    this.cropAreaTarget.classList.remove("hidden")

    // 枠の中は、切り抜いた結果のプレビューに切りかえる
    if (this.hasImageTarget) this.imageTarget.classList.add("hidden")
    if (this.hasPlaceholderTarget) this.placeholderTarget.classList.add("hidden")
    this.previewTarget.classList.remove("hidden")

    this.cropper = new Cropper(this.cropImageTarget, {
      aspectRatio: this.aspectValue, // 決めた比率で切り抜く
      viewMode: 1, // 画像の外は切り抜けない
      dragMode: "move", // ドラッグで画像を動かす
      autoCropArea: 1, // 切り抜く範囲は、場所いっぱい
      cropBoxMovable: false, // 切り抜く範囲は動かさない。画像のほうを動かす
      cropBoxResizable: false,
      toggleDragModeOnDblclick: false,
      guides: false,
      center: false,
      highlight: false,
      background: false,
      preview: this.previewTarget,
      // 準備ができたら、今の大きさを「スライダーの1倍」として覚える
      ready: () => {
        this.baseRatio = this.cropper.getImageData().width / this.cropper.getImageData().naturalWidth
        this.zoomTarget.value = 1
      },
      // 指でつまむ・ホイールで拡大縮小したときも、スライダーを合わせる(1倍より小さくはしない)
      zoom: (event) => {
        if (!this.baseRatio) return
        if (event.detail.ratio < this.baseRatio) {
          event.preventDefault()
          this.cropper.zoomTo(this.baseRatio)
          return
        }
        this.zoomTarget.value = event.detail.ratio / this.baseRatio
      }
    })
  }

  // スライダーを動かしたら、その倍率に拡大縮小する
  zoom() {
    if (!this.cropper || !this.baseRatio) return
    this.cropper.zoomTo(this.baseRatio * this.zoomTarget.value)
  }

  // フォームを送る前に、切り抜いた画像に差しかえてから送る
  submit(event) {
    if (!this.cropper || this.cropped) return

    event.preventDefault()
    const submitter = event.submitter
    // png・webp はそのまま、それ以外は jpeg にする
    const type = ["image/png", "image/webp"].includes(this.fileType) ? this.fileType : "image/jpeg"
    const canvas = this.cropper.getCroppedCanvas({ width: this.widthValue, height: this.heightValue, imageSmoothingQuality: "high" })

    canvas.toBlob((blob) => {
      const extension = type.split("/")[1]
      const file = new File([blob], `image.${extension}`, { type })
      const dataTransfer = new DataTransfer()
      dataTransfer.items.add(file)
      this.fileInputTarget.files = dataTransfer.files

      // 差しかえが終わったので、もう一度送る(今度は切り抜かずにそのまま送られる)
      this.cropped = true
      this.form.requestSubmit(submitter)
    }, type, 0.9)
  }

  // 切り抜きの道具を片付ける(画像を選びなおしたときと、別の画面に移るとき)
  // 画像を一時的に見せるために作った URL も、ここで捨てる
  destroyCropper() {
    if (!this.cropper) return

    URL.revokeObjectURL(this.cropImageTarget.src)
    this.cropper.destroy()
    this.cropper = null
  }
}
