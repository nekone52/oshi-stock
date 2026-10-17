class Item < ApplicationRecord
  # カテゴリを削除してもグッズは残す（category_id を空にする）ため、空っぽでもOKにする
  belongs_to :category, optional: true

  # グッズは必ず推しキャラに紐づく（キャラを消したらグッズも消える）
  belongs_to :character

  # 【商品画像】グッズ1つにつき画像1枚を紐付ける（Active Storage）
  # 表示用に、縦横600px以内に小さくしたもの(:display)も作れるようにする
  has_one_attached :image do |attachable|
    attachable.variant :display, resize_to_limit: [ 600, 600 ]
  end

  # グッズの状態を数字（0, 1, 2）で管理し、プログラム上では英語名で扱えるようにする
  # 0: wanted（ほしい） / 1: reserved（予約中） / 2: owned（所持）
  # validate: true … フォームから決まっていない名前(例: "hack")が送られてきたら、エラーで止めずに「不正な値です」と画面に出す
  enum :status, { wanted: 0, reserved: 1, owned: 2 }, validate: true

  # 【並べ方】未払いを先に、支払い期限の近い順に並べる(期限が未定のものは、未払いの中で最後になる)
  # -> { } で包んでおくと、.unpaid_first と書くたびに、そのときのデータで並べてくれる
  scope :unpaid_first, -> { reorder(paid: :asc, payment_deadline: :asc) }

  # 【グッズ名】入力必須（空っぽ禁止）＆ 長すぎ防止のため最大50文字まで
  validates :name, presence: true, length: { maximum: 50 }

  # 【単価】0円以上の整数のみ（マイナス価格を防止）。未入力でも保存できるように allow_nil: true
  validates :price, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true

  # 【個数】入力必須 ＆ 1個以上の整数のみ（0個やマイナス個で登録されるのを防止）
  # 空のときは presence の「入力してください」だけを出すため、数字のチェックは allow_nil: true にする
  validates :quantity, presence: true
  validates :quantity, numericality: { only_integer: true, greater_than_or_equal_to: 1 }, allow_nil: true
  # 【目標個数】1個以上の整数のみ。スイッチがオフ(目標なし)のときは空っぽでOKなので allow_nil: true
  # 【自分の言葉】一個以上の目標数だけ設定できる(0個や小数ははじく。空っぽ = 目標なしはOK)
  validates :target_quantity, numericality: { only_integer: true, greater_than_or_equal_to: 1 }, allow_nil: true

  # 【画像のチェック】ファイル形式（JPEG/PNG/WebP）と ファイル容量の上限（5MB未満）。メッセージは推しキャラのアイコンとそろえる
  validates :image,
            content_type: { in: %w[image/jpeg image/png image/webp], message: "は JPEG, PNG, WebP 形式にしてください" },
            size: { less_than: 5.megabytes, message: "は 5MB 以下にしてください" }

  # 【商品URL】「http://」や「https://」で始まる正しいURL形式のみ。未入力でも保存できるように allow_blank: true
  # \A(最初)と \z(最後)ではさんで、前後に余計な文字があるものは通さない
  validates :url, format: { with: /\A#{URI::DEFAULT_PARSER.make_regexp(%w[http https])}\z/ }, allow_blank: true
end
