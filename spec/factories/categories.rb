FactoryBot.define do
  factory :category do
    # 名前は重ならないように、1件ごとに番号を変える(最初の5種類とも重ならない)
    sequence(:name) { |n| "カテゴリ#{n}" }
    user
  end
end
