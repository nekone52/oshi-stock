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

  it "各セクションは4つまで出す" do
    5.times { |n| create(:item, character: hinata, name: "ほしい物#{n + 1}", status: :wanted) }
    get root_path
    section = response.body[/ほしい物リスト.*?予約注文中/m]

    # 新しい順に4つ(ほしい物5〜2)。いちばん古い ほしい物1 と、最初からある ヒナタの缶バッジ は出ない
    expect(section).to include("ほしい物5", "ほしい物2")
    expect(section).not_to include("ほしい物1")
  end

  # 下のメニューがないので、見出しの横のリンクがほかの画面への入口になる
  it "見出しの横に、件数に関係なくいつも「ほしい物」「予約」「グッズ一覧」へのリンクを出す" do
    get root_path
    body = response.body

    expect(body[/ほしい物リスト.*?予約注文中/m]).to include("ほしい物 <span", goods_path(status: "wanted"))
    expect(body[/予約注文中.*?所持グッズ/m]).to include("予約 <span", reservations_path)
    expect(body[/所持グッズ.*?グッズを登録/m]).to include("グッズ一覧 <span", goods_path(status: "owned"))
  end

  it "推しを選んでいたら、「予約 →」にその推しの番号をつけて、予約画面へ引きつぐ" do
    get root_path(character_id: hinata.id)
    expect(response.body[/予約注文中.*?所持グッズ/m]).to include(reservations_path(character_id: hinata.id))
  end
end
