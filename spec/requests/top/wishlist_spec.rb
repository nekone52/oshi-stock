require "rails_helper"

RSpec.describe "ほしい物リスト(予約の予定ごと・#104)", type: :request do
  let(:user) { create(:user) }
  let(:character) { create(:character, user: user, name: "ヒナタ") }

  before do
    create(:item, character: character, name: "受付中のアクスタ", reservation_deadline_on: Date.current + 3)
    create(:item, character: character, name: "開始前のぬい", reservation_start_on: Date.current + 5)
    create(:item, character: character, name: "〆切すぎの缶バッジ", reservation_deadline_on: Date.current - 1)
    sign_in_as(user)
  end

  it "ホームに、予約の予定ごとの見出しとチップが出る" do
    get root_path
    expect(response.body).to include("予約受付中(〆切が近い順)", "予約開始前", "〆切すぎ")
    expect(response.body).to include("予約受付中 〆 ", "から")
  end

  it "「予約した」「届いた」のボタンが出る" do
    get root_path
    item = Item.find_by!(name: "受付中のアクスタ")
    expect(response.body).to include(reserve_good_path(item), receive_good_path(item), "予約した", "届いた")
  end

  it "「諦めた」は、押す前に確認(data-turbo-confirm)が出る消去ボタン" do
    get root_path
    expect(response.body).to include("諦めた", "を諦める?", "data-turbo-confirm", 'name="_method" value="delete"')
  end

  it "グッズ一覧の「ほしい物」タブも、同じ予約の予定ごとの見た目になる" do
    get goods_path(status: "wanted")
    expect(response.body).to include("予約受付中(〆切が近い順)", "予約開始前", "〆切すぎ", "予約した", "諦めた")
  end
end
