require "rails_helper"

# ホーム画面:グッズ名の検索
RSpec.describe "ホーム画面(検索)", type: :request do
  let(:user) { create(:user) }
  include_context "ホームの推しとグッズ"

    it "グッズ名で検索すると、その言葉をふくむグッズだけを出す" do
      get root_path(q: "アクスタ")
      body = response.body

      expect(body).to include("ヒナタのアクスタ", "「アクスタ」の検索結果")
      expect(body).not_to include("ヒナタの缶バッジ")
    end

    it "検索の言葉に % があっても、全部のグッズが当たってしまわない" do
      get root_path(q: "%")
      expect(response.body).not_to include("ヒナタのアクスタ")
    end
end
