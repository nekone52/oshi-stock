FactoryBot.define do
  factory :character do
    # 名前は重ならないように、1件ごとに番号を変える
    sequence(:name) { |n| "推し#{n}" }
    color { "#E8577A" }
    user
  end
end
