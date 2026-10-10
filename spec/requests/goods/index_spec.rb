require "rails_helper"

# グッズの一覧(ホームの「ほしい物 →」「グッズ一覧 →」の先)。状態・推し・カテゴリ・検索でしぼれる
RSpec.describe "グッズの一覧", type: :request do
  let(:user) { create(:user) }
  let!(:hinata) { create(:character, user: user, name: "ヒナタ") }
  let!(:aoi) { create(:character, user: user, name: "アオイ") }

  before do
    create(:item, character: hinata, name: "ヒナタのアクスタ", status: :owned, category: user.categories.find_by!(name: "アクスタ"))
    create(:item, character: hinata, name: "ヒナタの缶バッジ", status: :wanted, category: user.categories.find_by!(name: "缶バッジ"))
    create(:item, character: aoi, name: "アオイのぬい", status: :reserved, paid: false)
    create(:item, character: create(:character, user: create(:user)), name: "ほかの人のグッズ", status: :owned)
  end

  it "ログインしていないと、ログイン画面へ移る" do
    get goods_path
    expect(response).to redirect_to(new_session_path)
  end

  context "ログインしているとき" do
    before { sign_in_as(user) }

    it "すべてのときは、自分のグッズを全部出す(ほかの人のグッズは出さない)" do
      get goods_path
      expect(response.body).to include("ヒナタのアクスタ", "ヒナタの缶バッジ", "アオイのぬい")
      expect(response.body).not_to include("ほかの人のグッズ")
    end

    it "状態(status)でしぼれる" do
      get goods_path(status: "owned")
      expect(response.body).to include("ヒナタのアクスタ")
      expect(response.body).not_to include("ヒナタの缶バッジ")
      expect(response.body).not_to include("アオイのぬい")
    end

    it "決まっていない状態が送られてきたら、しぼらずに全部出す" do
      get goods_path(status: "hack")
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("ヒナタのアクスタ", "アオイのぬい")
    end

    it "推しでしぼれる(ホームの絞り込みを引きつぐ)" do
      get goods_path(character_id: aoi.id)
      expect(response.body).to include("アオイのぬい")
      expect(response.body).not_to include("ヒナタのアクスタ")
    end

    it "カテゴリでしぼれる" do
      get goods_path(category_id: user.categories.find_by!(name: "缶バッジ").id)
      expect(response.body).to include("ヒナタの缶バッジ")
      expect(response.body).not_to include("ヒナタのアクスタ")
    end

    it "グッズ名で検索できる" do
      get goods_path(q: "ぬい")
      expect(response.body).to include("アオイのぬい")
      expect(response.body).not_to include("ヒナタのアクスタ")
    end
  end
end
