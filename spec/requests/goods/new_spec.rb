require "rails_helper"

# グッズを登録の画面
RSpec.describe "グッズを登録の画面", type: :request do
  let(:user) { create(:user) }

  # 「いまの状態」のラジオボタンで、どれが選ばれているか(checked がついているか)
  def checked_status(body)
    body[/<input[^>]*checked="checked"[^>]*name="item\[status\]"[^>]*>/].to_s[/value="(\w+)"/, 1]
  end

  describe "GET /goods/new" do
    before { sign_in_as(user) }

    it "ふつうに開くと、「ほしい物」が選ばれている" do
      get new_good_path
      expect(checked_status(response.body)).to eq("wanted")
    end

    it "予約画面から(?status=reserved)開くと、「予約中」が選ばれている" do
      get new_good_path(status: "reserved")
      expect(checked_status(response.body)).to eq("reserved")
    end

    it "決まっていない status(?status=hack)は無視して、「ほしい物」のまま" do
      get new_good_path(status: "hack")
      expect(response).to have_http_status(:ok)
      expect(checked_status(response.body)).to eq("wanted")
    end
  end
end
