class Character < ApplicationRecord
  belongs_to :user
  # 推しはたくさんのグッズを持つ ＆ 推しを消したらグッズも道連れで削除
  has_many :items, dependent: :destroy
  # アイコン画像(1人に1枚)。表示用に、縦横600px以内に小さくしたもの(:display)も作れるようにする
  has_one_attached :icon do |attachable|
    attachable.variant :display, resize_to_limit: [ 600, 600 ]
  end

  # 推しの色が登録されていないときに使う色(アプリのピンク)
  DEFAULT_COLOR = "#E8577A".freeze

  # 画面で使う推しの色(未登録なら DEFAULT_COLOR)
  def display_color
    color.presence || DEFAULT_COLOR
  end

  # 状態ごとのグッズの数(例:{ "wanted" => 1, "reserved" => 1, "owned" => 2 })。0件の状態は入らないので、画面では || 0 で読む
  # group(:status).count で、データベースに1回聞くだけで3つの数がそろう
  def item_counts
    items.group(:status).count
  end

  # 所持グッズの合計金額(単価 × 個数 を、所持のグッズぶんたす)。単価が空のグッズは数えない
  def owned_total
    items.owned.sum("price * quantity")
  end

  # 【推しの色のお掃除係】明るすぎ・暗すぎ・ギラギラの色は、保存する前に落ち着いた色に直す(app/models/oshi_color.rb)
  # 【自分の言葉】モデルがデータを管理しているから、保存する前に色を整えるのもモデルに書く
  normalizes :color, with: ->(color) { OshiColor.soften(color) }

  validates :name, presence: true, length: { maximum: 50 }
  # 色は「#」+ 16進数6桁(例:#E8577A)だけ。画面の style に入れるので、それ以外の文字を入れさせない
  validates :color, format: { with: /\A#\h{6}\z/ }, allow_blank: true
  # アイコン画像は JPEG・PNG・WebP の画像だけ、5MB 未満まで(active_storage_validations)
  validates :icon,
            content_type: { in: %w[image/jpeg image/png image/webp], message: "は JPEG, PNG, WebP 形式にしてください" },
            size: { less_than: 5.megabytes, message: "は 5MB 以下にしてください" }
end
