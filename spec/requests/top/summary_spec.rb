require "rails_helper"

# ホーム画面:これから支払う金額のまとめ
RSpec.describe "ホーム画面(これから支払う金額)", type: :request do
  let(:user) { create(:user) }
  include_context "ホームの推しとグッズ"

    it "これから支払う金額は、支払っていない予約中・所持のグッズの合計(単価 × 個数)" do
      get root_path
      # ヒナタのアクスタ 1650 × 2 + アオイのタオル 1000 = 4300(アオイのぬいは支払い済み、缶バッジはほしい物なので数えない)
      expect(response.body).to include("¥4,300", "未払い 2件", "期限7日以内 1件")
    end
end
