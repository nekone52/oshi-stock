require "rails_helper"

# 予約の一覧
RSpec.describe "予約の一覧", type: :request do
  let(:user) { create(:user) }

  describe "GET /reservations" do
    it "ログインしていないと、ログイン画面へ移る" do
      get reservations_path
      expect(response).to redirect_to(new_session_path)
    end

    it "ログインしていれば、予約の画面が開ける" do
      sign_in_as(user)
      get reservations_path
      expect(response).to have_http_status(:ok)
    end
  end
end
