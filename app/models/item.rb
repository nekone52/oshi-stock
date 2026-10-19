class Item < ApplicationRecord
  belongs_to :category, optional: true

  belongs_to :character

  has_one_attached :image do |attachable|
    attachable.variant :display, resize_to_limit: [ 600, 600 ]
  end

  enum :status, { wanted: 0, reserved: 1, owned: 2 }, validate: true

  scope :unpaid_first, -> { reorder(paid: :asc, payment_deadline: :asc) }
  scope :search_name, ->(query) { where("items.name ILIKE ?", "%#{sanitize_sql_like(query)}%") }

  validates :name, presence: true, length: { maximum: 50 }

  validates :price,
            numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 1_000_000 },
            allow_nil: true

  validates :quantity, presence: true
  validates :quantity,
            numericality: { only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: 999 },
            allow_nil: true
  validates :target_quantity,
            numericality: { only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: 999 },
            allow_nil: true

  validates :image,
            content_type: { in: %w[image/jpeg image/png image/webp], message: "は JPEG, PNG, WebP 形式にしてください" },
            size: { less_than: 5.megabytes, message: "は 5MB 以下にしてください" }

  validates :url, format: { with: /\A#{URI::DEFAULT_PARSER.make_regexp(%w[http https])}\z/ }, allow_blank: true

  def secured_quantity
    wanted? ? 0 : quantity
  end
end
