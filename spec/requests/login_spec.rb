require "rails_helper"

RSpec.describe "Login", type: :request do
  describe "GET /login" do
    it "ログイン画面が表示される" do
      get login_path

      expect(response).to have_http_status(:ok)
      # 見た目は Issue 34 でモックのものに差し替える。今はログインの送り先があることを確かめる
      expect(response.body).to include('/session" accept-charset')
    end
  end
end
