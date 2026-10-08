require "rails_helper"

# ホーム画面:ほしい物・予約注文中・所持の3つのセクション
RSpec.describe "ホーム画面(3つのセクション)", type: :request do
  let(:user) { create(:user) }
  include_context "ホームの推しとグッズ"

    it "自分のグッズを、ほしい物・予約注文中・所持の3つに分けて出す(ほかの人のグッズは出さない)" do
      get root_path
      body = response.body

      expect(body).to include("ヒナタの缶バッジ", "ヒナタのアクスタ", "アオイのぬい", "アオイのタオル")
      expect(body).not_to include("ほかの人のグッズ")
    end

    it "グッズのカードを押すと、そのグッズの詳細へ行ける" do
      get root_path
      Item.joins(:character).where(characters: { user_id: user.id }).find_each do |item|
        expect(response.body).to include(good_path(item))
      end
    end
end
