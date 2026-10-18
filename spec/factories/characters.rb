FactoryBot.define do
  factory :character do
    sequence(:name) { |n| "推し#{n}" }
    color { "#E8577A" }
    user
  end
end
