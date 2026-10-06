FactoryBot.define do
  factory :item do
    # 名前は重ならないように、1件ごとに番号を変える
    sequence(:name) { |n| "グッズ#{n}" }
    character
  end
end
