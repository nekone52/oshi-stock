require "rails_helper"

RSpec.describe "パスワードの再設定", type: :request do
  let!(:user) { create(:user, email_address: "oshi@example.com") }

  it "ログインしていなくても、再設定の画面が開ける" do
    get new_password_path
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("パスワードの再設定")
  end

  it "メールアドレスを送ると、再設定のメールが送られる" do
    expect {
      post passwords_path, params: { email_address: "oshi@example.com" }
    }.to have_enqueued_mail(PasswordsMailer, :reset)
    expect(response).to redirect_to(new_session_path)
  end

  it "新しいパスワードに変えると、そのパスワードでログインできる" do
    token = user.password_reset_token
    get edit_password_path(token)
    expect(response.body).to include("新しいパスワード")

    put password_path(token), params: { password: "newpassword", password_confirmation: "newpassword" }
    expect(response).to redirect_to(new_session_path)
    expect(user.reload.authenticate("newpassword")).to eq(user)
  end

  it "確認用と一致しないと、変更できない" do
    token = user.password_reset_token
    put password_path(token), params: { password: "newpassword", password_confirmation: "different" }
    expect(response).to redirect_to(edit_password_path(token))
    expect(user.reload.authenticate("password")).to eq(user)
  end
end
