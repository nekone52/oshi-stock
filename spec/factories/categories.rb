FactoryBot.define do
  factory :category do
    sequence(:name) { |n| "カテゴリ#{n}" }
    user
  end
end
