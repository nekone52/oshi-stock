# Pin npm packages by running ./bin/importmap

pin "application"
# 確認ダイアログをアプリの見た目にする(app/javascript/confirm_dialog.js)
pin "confirm_dialog"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin_all_from "app/javascript/controllers", under: "controllers"
# 推しのアイコンの拡大・縮小・切り抜き(oshi_preview_controller.js で使う。見た目は app/assets/stylesheets/cropper.css)
pin "cropperjs" # @1.6.2
