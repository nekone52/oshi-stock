require "rails_helper"

RSpec.describe "ホーム画面(これから支払う金額)", type: :request do
  let(:user) { create(:user) }
  include_context "ホームの推しとグッズ"

    it "これから支払う金額は、支払っていない予約中・所持のグッズの合計(単価 × 個数)" do
      get root_path
      expect(response.body).to include("¥4,300", "未払い 2件", "期限7日以内 1件")
    end
end
