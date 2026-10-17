# メールの見本(プレビュー)。開発中に http://localhost:3000/rails/mailers で、送らずに見た目だけ見られる
# 本番では見られない(Rails がはじめから開発中だけにしている)
class PasswordsMailerPreview < ActionMailer::Preview
  # パスワード再設定メール。開発用のデータベースの、いちばん最初のユーザーあてに作ってみる
  def reset
    PasswordsMailer.reset(User.first)
  end
end
