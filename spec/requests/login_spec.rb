require "rails_helper"

RSpec.describe "Login", type: :request do
  describe "GET /login" do
    it "ログイン画面が表示される" do
      get login_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("ログイン")
    end
  end
end
