class Category < ApplicationRecord
  # このカテゴリは1人のユーザーに所属している
  belongs_to :user
  # カテゴリはたくさんのグッズを持つ ＆ カテゴリを消したらグッズの category_id を空（NULL）にする
  has_many :items, dependent: :nullify

  # カテゴリ名のチェックルール
  validates :name,
    presence: true,                    # ① 空っぽ（nil や ""）は保存させない
    length: { maximum: 20 },           # ② 最大20文字まで（長すぎる名前を防ぐ）
    uniqueness: { scope: :user_id }    # ③ 「同じ user_id の中」で名前が重複していたらダメ
end
