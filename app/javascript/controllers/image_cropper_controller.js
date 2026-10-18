import { Controller } from "@hotwired/stimulus"
import Cropper from "cropperjs"

export default class extends Controller {
  static values = { aspect: Number, width: Number, height: Number }

  static targets = ["fileInput", "cropArea", "cropImage", "zoom", "preview", "image", "placeholder"]

  connect() {
    this.form = this.element.closest("form")
    this.submitHandler = this.submit.bind(this)
    this.form?.addEventListener("submit", this.submitHandler)
  }

  disconnect() {
    this.form?.removeEventListener("submit", this.submitHandler)
    this.destroyCropper()
  }

  choose(event) {
    const file = event.target.files[0]
    if (!file) return

    this.destroyCropper()
    this.fileType = file.type
    this.cropped = false
    this.cropImageTarget.src = URL.createObjectURL(file)
    this.cropAreaTarget.classList.remove("hidden")

    if (this.hasImageTarget) this.imageTarget.classList.add("hidden")
    if (this.hasPlaceholderTarget) this.placeholderTarget.classList.add("hidden")
    this.previewTarget.classList.remove("hidden")

    this.cropper = new Cropper(this.cropImageTarget, {
      aspectRatio: this.aspectValue,
      viewMode: 1,
      dragMode: "move",
      autoCropArea: 1,
      cropBoxMovable: false,
      cropBoxResizable: false,
      toggleDragModeOnDblclick: false,
      guides: false,
      center: false,
      highlight: false,
      background: false,
      preview: this.previewTarget,
      ready: () => {
        this.baseRatio = this.cropper.getImageData().width / this.cropper.getImageData().naturalWidth
        this.zoomTarget.value = 1
      },
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

  zoom() {
    if (!this.cropper || !this.baseRatio) return
    this.cropper.zoomTo(this.baseRatio * this.zoomTarget.value)
  }

  submit(event) {
    if (!this.cropper || this.cropped) return

    event.preventDefault()
    const submitter = event.submitter
    const type = ["image/png", "image/webp"].includes(this.fileType) ? this.fileType : "image/jpeg"
    const canvas = this.cropper.getCroppedCanvas({ width: this.widthValue, height: this.heightValue, imageSmoothingQuality: "high" })

    canvas.toBlob((blob) => {
      const extension = type.split("/")[1]
      const file = new File([blob], `image.${extension}`, { type })
      const dataTransfer = new DataTransfer()
      dataTransfer.items.add(file)
      this.fileInputTarget.files = dataTransfer.files

      this.cropped = true
      this.form.requestSubmit(submitter)
    }, type, 0.9)
  }

  destroyCropper() {
    if (!this.cropper) return

    URL.revokeObjectURL(this.cropImageTarget.src)
    this.cropper.destroy()
    this.cropper = null
  }
}
