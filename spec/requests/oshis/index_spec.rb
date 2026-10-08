require "rails_helper"

# 推しキャラの一覧(名刺)
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

    it "「…」メニューに、その推しの編集と削除のリンクがある" do
      character = create(:character, user: user)

      sign_in_as(user)
      get oshis_path
      expect(response.body).to include(edit_oshi_path(character))
      expect(response.body).to include(confirm_delete_oshi_path(character))
    end
  end
end
