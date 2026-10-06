class ApplicationController < ActionController::Base
  # 【会員制ドアの合鍵】
  # ログインチェックやログイン中のユーザー情報を、アプリ全体で使えるようにする
  include Authentication

  # 【古い端末への通行止め（本番のみ）】
  # 開発中はスマホ表示のテストを邪魔させず、本番公開時だけ動かす
  if Rails.env.production?
    # デザインが崩れる古いブラウザだけお断りして、少し古いスマホは通す設定
    allow_browser versions: { safari: 16.4, chrome: 111, firefox: 128 }
  end

  # 【JSの変更検知】
  # JavaScript（importmap）を更新したとき、ブラウザ側の古いキャッシュを自動で無効化する
  stale_when_importmap_changes
end
