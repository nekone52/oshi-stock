import { Controller } from "@hotwired/stimulus"
import Cropper from "cropperjs"

// 【推しの登録・編集画面のプレビューと、アイコンの切り抜き】
// HTML では data-controller="oshi-preview" と書いて使う(form に付ける)
export default class extends Controller {
  // HTML側で名札をつけたものを受け取る
  //   color:色の入力欄 / bar:色の帯 / image:今のアイコン / placeholder:画像がないときの絵
  //   fileInput:画像を選ぶ欄 / cropArea:切り抜きの場所 / cropImage:切り抜く画像
  //   cropPreview:丸い枠の中の、切り抜いた結果のプレビュー / zoom:拡大縮小のスライダー
  static targets = ["color", "bar", "image", "placeholder", "fileInput", "cropArea", "cropImage", "cropPreview", "zoom"]

  // 画面を開いたときにも、今の色で帯を塗る(入力ミスで画面が戻ってきたときのため)
  connect() {
    this.updateColor()
  }

  // 別の画面に移るときは、切り抜きの道具を片付ける
  disconnect() {
    this.destroyCropper()
  }

  // 選んだ色 → 薄い色 → 白 のグラデーションで、帯を塗りなおす
  updateColor() {
    const color = this.colorTarget.value
    this.barTarget.style.backgroundImage = `linear-gradient(to right, ${color}, color-mix(in srgb, ${color} 20%, white), white)`
  }

  // 画像を選んだら、切り抜きの場所に出す(まだ保存はしていない)
  updateImage(event) {
    const file = event.target.files[0]
    if (!file) return

    this.destroyCropper()
    this.fileType = file.type
    this.cropped = false
    this.cropImageTarget.src = URL.createObjectURL(file)
    this.cropAreaTarget.classList.remove("hidden")

    // 丸い枠は、切り抜いた結果のプレビューに切りかえる
    this.imageTarget.classList.add("hidden")
    this.placeholderTarget.classList.add("hidden")
    this.cropPreviewTarget.classList.remove("hidden")

    this.cropper = new Cropper(this.cropImageTarget, {
      aspectRatio: 1, // 正方形で切り抜く
      viewMode: 1, // 画像の外は切り抜けない
      dragMode: "move", // ドラッグで画像を動かす
      autoCropArea: 1, // 切り抜く範囲は、場所いっぱい
      cropBoxMovable: false, // 切り抜く範囲(丸)は動かさない。画像のほうを動かす
      cropBoxResizable: false,
      toggleDragModeOnDblclick: false,
      guides: false,
      center: false,
      highlight: false,
      background: false,
      preview: this.cropPreviewTarget,
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

  // 「登録する」「保存する」を押したら、切り抜いた画像に差しかえてから送る
  submit(event) {
    if (!this.cropper || this.cropped) return

    event.preventDefault()
    const submitter = event.submitter
    // png・webp はそのまま、それ以外は jpeg にする(縦横600pxにそろえる)
    const type = ["image/png", "image/webp"].includes(this.fileType) ? this.fileType : "image/jpeg"
    const canvas = this.cropper.getCroppedCanvas({ width: 600, height: 600, imageSmoothingQuality: "high" })

    canvas.toBlob((blob) => {
      const extension = type.split("/")[1]
      const file = new File([blob], `icon.${extension}`, { type })
      const dataTransfer = new DataTransfer()
      dataTransfer.items.add(file)
      this.fileInputTarget.files = dataTransfer.files

      // 差しかえが終わったので、もう一度送る(今度は切り抜かずにそのまま送られる)
      this.cropped = true
      this.element.requestSubmit(submitter)
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
