class Character < ApplicationRecord
  belongs_to :user
  has_many :items, dependent: :destroy
  has_one_attached :icon do |attachable|
    attachable.variant :display, resize_to_limit: [ 600, 600 ]
  end

  DEFAULT_COLOR = "#E8577A".freeze

  def display_color
    color.presence || DEFAULT_COLOR
  end

  def item_counts
    items.group(:status).count
  end

  def owned_total
    items.owned.sum("price * quantity")
  end

  normalizes :color, with: ->(color) { OshiColor.soften(color) }

  validates :name, presence: true, length: { maximum: 50 }
  validates :color, format: { with: /\A#\h{6}\z/ }, allow_blank: true
  validates :icon,
            content_type: { in: %w[image/jpeg image/png image/webp], message: "は JPEG, PNG, WebP 形式にしてください" },
            size: { less_than: 5.megabytes, message: "は 5MB 以下にしてください" }
end
