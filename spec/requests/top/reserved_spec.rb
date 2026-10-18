require "rails_helper"

RSpec.describe "ホーム画面(予約注文中)", type: :request do
  let(:user) { create(:user) }
  include_context "ホームの推しとグッズ"

    it "予約注文中に「支払った」「届いた」のボタンがある" do
      reserved_item = Item.find_by!(name: "ヒナタのアクスタ")
      get root_path

      expect(response.body).to include(toggle_paid_good_path(reserved_item), receive_good_path(reserved_item))
    end

    it "届いたけど未払いのものは、予約注文中にも「届いた・未払い」として残す" do
      get root_path
      expect(response.body).to include("届いた・未払い")
      expect(response.body.scan("アオイのタオル").size).to be >= 2
    end

    it "予約注文中は、未払いを先に、支払い期限の近い順に並べる" do
      create(:item, character: hinata, name: "期限が近い未払い", status: :reserved, paid: false, payment_deadline: Date.current + 1)
      get root_path
      section = response.body[/予約注文中.*?所持グッズ/m]

      expect(section.index("期限が近い未払い")).to be < section.index("ヒナタのアクスタ")
      expect(section.index("ヒナタのアクスタ")).to be < section.index("アオイのタオル")
      expect(section.index("アオイのタオル")).to be < section.index("アオイのぬい")
    end
end
