require "rails_helper"

RSpec.describe ItemsHelper, type: :helper do
  describe "#back_path_for" do
    it "予約中なら、予約画面" do
      expect(helper.back_path_for(build(:item, status: :reserved))).to eq(reservations_path)
    end

    it "届いたけど未払いなら、予約画面(予約画面に出ているので)" do
      expect(helper.back_path_for(build(:item, status: :owned, paid: false))).to eq(reservations_path)
    end

    it "ほしい物なら、グッズ一覧(ほしい物)" do
      expect(helper.back_path_for(build(:item, status: :wanted))).to eq(goods_path(status: "wanted"))
    end

    it "所持で支払い済みなら、グッズ一覧(所持)" do
      expect(helper.back_path_for(build(:item, status: :owned, paid: true))).to eq(goods_path(status: "owned"))
    end
  end
end
