require "rails_helper"

# 推しキャラの詳細
RSpec.describe "推しキャラの詳細", type: :request do
  let(:user) { create(:user) }

  describe "GET /oshis/:id" do
    let(:character) { create(:character, user: user) }

    it "ログインしていないと、ログイン画面へ移る" do
      get oshi_path(character)
      expect(response).to redirect_to(new_session_path)
    end

    it "自分の推しなら、詳細画面が開ける" do
      sign_in_as(user)
      get oshi_path(character)
      expect(response).to have_http_status(:ok)
    end

    it "上の数の箱に、状態ごとの数と所持の合計金額が出る" do
      create(:item, character: character, status: :reserved, price: 1650)
      create(:item, character: character, status: :owned, price: 550, quantity: 3)
      create(:item, character: character, status: :owned, price: 5500)

      sign_in_as(user)
      get oshi_path(character)
      expect(response.body).to include("¥7,150")
    end

    it "下のグッズ一覧に、この推しのグッズが状態ごとに出る(ほかの推しのグッズは出ない)" do
      create(:item, character: character, name: "缶バッジ第3弾", status: :wanted)
      create(:item, character: character, name: "夏祭りアクスタ", status: :reserved)
      create(:item, character: character, name: "ぬい服セット", status: :owned, paid: true)
      create(:item, character: create(:character, user: user), name: "ほかの推しのグッズ")

      sign_in_as(user)
      get oshi_path(character)
      expect(response.body).to include("缶バッジ第3弾", "夏祭りアクスタ", "ぬい服セット")
      expect(response.body).not_to include("ほかの推しのグッズ")
    end

    it "グッズがない状態は「まだありません」が出る" do
      sign_in_as(user)
      get oshi_path(character)
      expect(response.body).to include("まだありません")
    end

    it "ほかのユーザーの推しは、見つからない(404)" do
      other_character = create(:character, user: create(:user))

      sign_in_as(user)
      get oshi_path(other_character)
      expect(response).to have_http_status(:not_found)
    end
  end
end
