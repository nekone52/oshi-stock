class User < ApplicationRecord
  # 【合言葉の金庫番】
  # パスワードを暗号化（ハッシュ化）して安全に保存・照合する
  has_secure_password

  # 【入場パスの管理と後片付け】
  # ユーザーが持つログインセッションを紐付け、退会時には自動で全セッションを削除する
  has_many :sessions, dependent: :destroy
  has_many :characters, dependent: :destroy
  # 推しキャラを通して、グッズもたくさん持っている(Current.user.items で「自分のグッズ」をまとめて取れる)
  # グッズは推しキャラの dependent: :destroy で消えるので、ここには dependent を書かない
  has_many :items, through: :characters
  # ユーザーが持つカテゴリ(推しキャラみんなで共有)。退会時には、そのカテゴリも削除する
  has_many :categories, dependent: :destroy

  # 【最初のカテゴリ】ユーザーが作られたら、最初の5種類のカテゴリを自動で作る
  after_create :create_default_categories

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

  # 【テーマの色のルールチェック】「#」+ 16進数6桁(例:#E8577A)だけ。画面の style に入れるので、それ以外の文字を入れさせない
  # 空っぽ禁止(presence)。空のときは「入力してください」だけ出すため、形のチェックは allow_blank にする
  validates :theme_color, presence: true, format: { with: /\A#\h{6}\z/, allow_blank: true }

  private

  # 最初の5種類のカテゴリを、このユーザーのカテゴリとして作る(あとから自分で増やしたり消したりできる)
  def create_default_categories
    %w[アクスタ 缶バッジ ぬいぐるみ ブロマイド その他].each do |name|
      categories.create!(name: name)
    end
  end
end
