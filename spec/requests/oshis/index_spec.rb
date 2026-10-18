require "rails_helper"

RSpec.describe "推しキャラの一覧", type: :request do
  let(:user) { create(:user) }

  describe "GET /oshis" do
    it "ログインしていないと、ログイン画面へ移る" do
      get oshis_path
      expect(response).to redirect_to(new_session_path)
    end

    it "推しがいないときは、「まだ推しがいません」を出す" do
      sign_in_as(user)
      get oshis_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("まだ推しがいません")
    end

    it "自分の推しだけを表示し、ほかのユーザーの推しは表示しない" do
      create(:character, user: user, name: "ヒナタ")
      create(:character, user: create(:user), name: "ほかの人の推し")

      sign_in_as(user)
      get oshis_path
      expect(response.body).to include("ヒナタ")
      expect(response.body).not_to include("ほかの人の推し")
    end

    it "名刺に、その推しの「ほしい・予約中・所持」の件数と、持っているグッズの個数が出る" do
      character = create(:character, user: user, name: "ヒナタ")
      create(:item, character: character, status: :wanted)
      create_list(:item, 2, character: character, status: :reserved)
      create(:item, character: character, status: :owned, price: 1650, quantity: 2)
      create(:item, character: create(:character, user: create(:user)), status: :owned, quantity: 99)

      sign_in_as(user)
      get oshis_path
      body = response.body
      expect(body).to match(%r{所持グッズ <span[^>]*>2</span>個})
      expect(body).to match(%r{ほしい</span><span[^>]*>1</span>})
      expect(body).to match(%r{予約中</span><span[^>]*>2</span>})
      expect(body).to match(%r{所持</span><span[^>]*>1</span>})
      expect(body).not_to match(%r{所持グッズ <span[^>]*>99</span>個})
    end

    it "「…」メニューに、その推しの編集と削除のリンクがある" do
      character = create(:character, user: user)

      sign_in_as(user)
      get oshis_path
      expect(response.body).to include(edit_oshi_path(character))
      expect(response.body).to include(confirm_delete_oshi_path(character))
    end
  end
end
