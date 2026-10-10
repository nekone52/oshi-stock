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

    it "上の箱に、これから支払う金額と件数が出る(ホームと同じ数字)" do
      character = create(:character, user: user)
      create(:item, character: character, status: :reserved, price: 3300, payment_deadline: Date.current + 2)
      create(:item, character: character, status: :reserved, price: 1000, paid: true)
      create(:item, character: character, status: :owned, price: 1000, quantity: 2)

      sign_in_as(user)
      get reservations_path
      expect(response.body).to include("¥5,300", "予約 3件", "未払い 2件", "期限7日以内 1件")
    end

    it "発売月ごとに、古い月から順に見出しが出る(未払いが先頭でも、月の順はくずれない)" do
      character = create(:character, user: user)
      create(:item, character: character, status: :reserved, name: "11月のぬい", release_month: Date.new(2026, 11, 1))
      create(:item, character: character, status: :reserved, name: "10月の缶バッジ", release_month: Date.new(2026, 10, 1), paid: true)

      sign_in_as(user)
      get reservations_path
      body = response.body
      expect(body).to include("10月発売", "11月発売")
      # 10月の見出し → 10月のグッズ → 11月の見出し → 11月のグッズ の順に並ぶ
      expect(body.index("10月発売")).to be < body.index("10月の缶バッジ")
      expect(body.index("10月の缶バッジ")).to be < body.index("11月発売")
      expect(body.index("11月発売")).to be < body.index("11月のぬい")
    end
  end
end
