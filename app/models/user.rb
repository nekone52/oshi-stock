class User < ApplicationRecord
  # 【合言葉の金庫番】
  # パスワードを暗号化（ハッシュ化）して安全に保存・照合する
  has_secure_password

  # 【入場パスの管理と後片付け】
  # ユーザーが持つログインセッションを紐付け、退会時には自動で全セッションを削除する
  has_many :sessions, dependent: :destroy

  # 【メールアドレスの表記ゆれ防止（お掃除係）】
  # 「入口（登録）」と「照合（ログイン）」の両方で、Railsが勝手にキレイにしてから処理してくれる
  # 前後の余分な空白を削り、英字をすべて小文字に統一して保存・検索する
  normalizes :email_address, with: ->(e) { e.strip.downcase }

  # 【メールアドレスのルールチェック】
  validates :email_address,
            presence: true,                              # 空白（未入力）はNG
            length: { maximum: 255 },                    # 最大255文字まで
            format: { with: URI::MailTo::EMAIL_REGEXP, allow_blank: true }, # 正しいメール形式か（Ruby標準）。空のときは「入力してください」だけ出す
            uniqueness: true                             # 重複登録NG（normalizesがあるためこれだけでOK）

  # 【パスワードのルールチェック】
  # has_secure_password が空チェックをするため presence: true は不要（重複エラー防止）
  validates :password,
            length: { minimum: 8 },                      # 8文字以上
            allow_nil: true                              # 編集時、パスワードを変更しないなら空欄でもOK
end
