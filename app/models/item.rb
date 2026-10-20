class Item < ApplicationRecord
  belongs_to :category, optional: true

  belongs_to :character

  has_one_attached :image do |attachable|
    attachable.variant :display, resize_to_limit: [ 600, 600 ]
  end

  enum :status, { wanted: 0, reserved: 1, owned: 2 }, validate: true

  scope :unpaid_first, -> { reorder(paid: :asc, payment_deadline: :asc) }
  scope :search_name, ->(query) { where("items.name ILIKE ?", "%#{sanitize_sql_like(query)}%") }
  scope :reserved_or_unpaid, -> { reserved.or(owned.where(paid: false)) }
  scope :payment_filter, ->(filter) {
    case filter
    when "unpaid" then where(paid: false)
    when "paid" then where(paid: true)
    when "arrived" then owned.where(paid: false)
    else all
    end
  }

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

  # ホームのほしい物リストに出す順番:受付中 → 開始前 → まだ分からない → 〆切すぎ
  RESERVATION_PHASES = %i[open upcoming unknown closed].freeze

  def secured_quantity
    wanted? ? 0 : quantity
  end

  # 予約の予定は保存しないで、今日の日付と予約開始日・〆切をくらべて毎回決める
  def reservation_phase(today = Date.current)
    return :closed if reservation_deadline_on.present? && reservation_deadline_on < today
    return :upcoming if reservation_start_on.present? && reservation_start_on > today
    return :open if reservation_start_on.present? || reservation_deadline_on.present?

    :unknown
  end

  # 予約の予定ごとに分けて、受付中は〆切が近い順・開始前は開始が近い順に並べる。limit があれば上から limit 個まで
  def self.group_by_reservation(items, today: Date.current, limit: nil)
    groups = items.group_by { |item| item.reservation_phase(today) }
    groups[:open]&.sort_by! { |item| [ item.reservation_deadline_on ? 0 : 1, item.reservation_deadline_on || today ] }
    groups[:upcoming]&.sort_by!(&:reservation_start_on)
    sorted = RESERVATION_PHASES.flat_map { |phase| groups[phase] || [] }
    sorted = sorted.first(limit) if limit
    sorted.chunk { |item| item.reservation_phase(today) }.to_a
  end
end
