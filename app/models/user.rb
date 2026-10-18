class User < ApplicationRecord
  has_secure_password

  has_many :sessions, dependent: :destroy
  has_many :characters, dependent: :destroy
  has_many :items, through: :characters
  has_many :categories, dependent: :destroy

  after_create :create_default_categories

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  validates :email_address,
            presence: true,
            length: { maximum: 255 },
            format: { with: URI::MailTo::EMAIL_REGEXP, allow_blank: true },
            uniqueness: true

  validates :password,
            length: { minimum: 8 },
            allow_nil: true

  normalizes :theme_color, with: ->(color) { OshiColor.soften(color) }

  validates :theme_color, presence: true, format: { with: /\A#\h{6}\z/, allow_blank: true }

  def unpaid_items
    items.where(paid: false).where.not(status: :wanted)
  end

  def unpaid_total
    unpaid_items.sum("COALESCE(items.price, 0) * items.quantity")
  end

  def due_soon_count
    unpaid_items.where(payment_deadline: Date.current..7.days.from_now.to_date).count
  end

  private

  def create_default_categories
    %w[アクスタ 缶バッジ ぬいぐるみ ブロマイド その他].each do |name|
      categories.create!(name: name)
    end
  end
end
