require "rails_helper"

# 写真の上のお店のタグ(#103)。タグと帯には data-shop-tag の目印がついている
RSpec.describe "写真のお店のタグ", type: :request do
  let(:user) { create(:user) }
  let(:character) { create(:character, user: user) }

  before { sign_in_as(user) }

  it "ホームの予約注文中・ほしい物には、写真の下にお店の帯を出す" do
    create(:item, character: character, status: :reserved, shop_name: "アニメイト通販")
    create(:item, character: character, status: :wanted, shop_name: "公式ショップ")
    get root_path

    expect(response.body).to match(/data-shop-tag="band"[^>]*>アニメイト通販</)
    expect(response.body).to match(/data-shop-tag="band"[^>]*>公式ショップ</)
    expect(response.body).not_to include(%(data-shop-tag="corner"))
  end

  it "届いた・未払いのものは帯を出し、届いて支払いも済んだものには出さない" do
    create(:item, character: character, status: :owned, paid: false, shop_name: "未払いのお店")
    create(:item, character: character, status: :owned, paid: true, shop_name: "支払い済みのお店")
    get root_path

    expect(response.body).to match(/data-shop-tag="band"[^>]*>未払いのお店</)
    expect(response.body).not_to match(/data-shop-tag="band"[^>]*>支払い済みのお店</)
  end

  it "予約画面には、写真の下にお店の帯を出す" do
    create(:item, character: character, status: :reserved, shop_name: "アニメイト通販")
    get reservations_path

    expect(response.body).to match(/data-shop-tag="band"[^>]*>アニメイト通販</)
  end

  it "グッズ一覧には、写真の左上にお店のタグを出す" do
    create(:item, character: character, status: :reserved, shop_name: "アニメイト通販")
    get goods_path

    expect(response.body).to match(/data-shop-tag="corner"[^>]*>アニメイト通販</)
    expect(response.body).not_to include(%(data-shop-tag="band"))
  end
end
