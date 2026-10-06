FactoryBot.define do
  factory :user do
    # メールアドレスは重ならないように、1件ごとに番号を変える
    sequence(:email_address) { |n| "user#{n}@example.com" }
    password { "password" }
    password_confirmation { "password" }
  end
end
