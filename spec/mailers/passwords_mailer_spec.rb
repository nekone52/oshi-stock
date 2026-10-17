require "rails_helper"

# パスワード再設定メールの中身のテスト(送られるかどうかは spec/requests/passwords_spec.rb)
RSpec.describe PasswordsMailer, type: :mailer do
  let(:user) { create(:user, email_address: "oshi@example.com") }
  # テストの中で、その人あての再設定メールを作る(本当には送らない)
  let(:mail) { PasswordsMailer.reset(user) }

  # 送り主が Resend で確認ずみの部屋でないと、本番で配達されない
  it "送り主は no-reply@send.oshi-stock.com" do
    expect(mail.from).to eq([ "no-reply@send.oshi-stock.com" ])
  end

  it "あて先は、その人のメールアドレス" do
    expect(mail.to).to eq([ "oshi@example.com" ])
  end

  it "件名に「パスワード再設定」が入っている" do
    # 【自分の言葉】件名にパスワード再設定と書いているか確認してね!
    expect(mail.subject).to include("パスワード再設定")
  end

  it "本文に、再設定のリンクが入っている" do
    # メールの日本語は送るときに変身(エンコード)しているので、戻した(decoded)HTML の本文を調べる
    body = mail.html_part.body.decoded
    expect(body).to include("パスワードを再設定する")
    # 合言葉(トークン)は作るたびに変わるので、再設定の画面への住所が入っているかを見る
    expect(body).to match(%r{/passwords/.+/edit})
  end
end
