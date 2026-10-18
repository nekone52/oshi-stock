require "rails_helper"

RSpec.describe PasswordsMailer, type: :mailer do
  let(:user) { create(:user, email_address: "oshi@example.com") }
  let(:mail) { PasswordsMailer.reset(user) }

  it "送り主は no-reply@send.oshi-stock.com" do
    expect(mail.from).to eq([ "no-reply@send.oshi-stock.com" ])
  end

  it "あて先は、その人のメールアドレス" do
    expect(mail.to).to eq([ "oshi@example.com" ])
  end

  it "件名に「パスワード再設定」が入っている" do
    expect(mail.subject).to include("パスワード再設定")
  end

  it "本文に、再設定のリンクが入っている" do
    body = mail.html_part.body.decoded
    expect(body).to include("パスワードを再設定する")
    expect(body).to match(%r{/passwords/.+/edit})
  end
end
