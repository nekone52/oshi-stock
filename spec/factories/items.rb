FactoryBot.define do
  factory :item do
    sequence(:name) { |n| "グッズ#{n}" }
    character
  end
end
