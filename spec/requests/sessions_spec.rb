require "rails_helper"

RSpec.describe "ログイン・ログアウト", type: :request do
  let!(:user) {
    create(:user, email_address: "oshi@example.com", password: "password", password_confirmation: "password")
  }

  describe "POST /session(ログイン)" do
    it "正しいメールアドレスとパスワードなら、ログインしてホームへ移る" do
      post session_path, params: { email_address: "oshi@example.com", password: "password" }
      expect(response).to redirect_to(root_url)

      follow_redirect!
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("ログインしました。")
    end

    it "メールアドレスの大文字・小文字や前後の空白がちがっても、ログインできる" do
      post session_path, params: { email_address: "  OSHI@example.com ", password: "password" }
      expect(response).to redirect_to(root_url)
    end

    it "パスワードがちがうと、ログイン画面に戻ってお知らせを出す" do
      post session_path, params: { email_address: "oshi@example.com", password: "wrong-password" }
      expect(response).to redirect_to(new_session_path)

      follow_redirect!
      expect(response.body).to include("メールアドレスかパスワードがちがいます。")
    end
  end

  describe "DELETE /session(ログアウト)" do
    it "ログアウトすると、ログイン画面に戻り、ホームには入れなくなる" do
      sign_in_as(user)
      delete session_path
      expect(response).to redirect_to(new_session_path)

      follow_redirect!
      expect(response.body).to include("ログアウトしました。")

      get root_path
      expect(response).to redirect_to(new_session_path)
    end
  end

  describe "設定の画面" do
    it "ログアウトのボタンがある" do
      sign_in_as(user)
      get settings_path
      expect(response.body).to include("ログアウト")
      expect(response.body).to include('name="_method" value="delete"')
    end
  end
end
