require "rails_helper"

# ホーム画面:推しのアイコンでの絞り込み
RSpec.describe "ホーム画面(推しの絞り込み)", type: :request do
  let(:user) { create(:user) }
  include_context "ホームの推しとグッズ"

    it "推しのアイコンを押すと、その推しのグッズだけを出す" do
      get root_path(character_id: aoi.id)
      body = response.body

      expect(body).to include("アオイのぬい", "アオイのタオル")
      expect(body).not_to include("ヒナタの缶バッジ")
      expect(body).not_to include("ヒナタのアクスタ")
    end

    it "ほかの人の推しの番号を入れても、ほかの人のグッズは出ない" do
      someone_character = Character.where.not(user: user).first
      get root_path(character_id: someone_character.id)

      expect(response).to have_http_status(:ok)
      expect(response.body).not_to include("ほかの人のグッズ")
    end
end
