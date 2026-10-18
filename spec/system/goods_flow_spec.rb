require "rails_helper"

RSpec.describe "推し・グッズの流れ", type: :system do
  let(:user) { create(:user, email_address: "flow@example.com") }

  it "ログインして、推しを登録し、グッズを登録・編集できる" do
    visit new_session_path
    fill_in "email_address", with: user.email_address
    fill_in "password", with: "password"
    click_button "ログイン"

    click_link "＋ 推しを登録する"
    fill_in "character[name]", with: "ヒナタ"
    click_button "登録する"

    expect(page).to have_current_path(oshis_path)
    expect(page).to have_content("推しを登録しました")
    expect(page).to have_content("ヒナタ")

    visit new_good_path
    fill_in "item[name]", with: "ヒナタのアクスタ"
    select "ヒナタ", from: "item[character_id]"
    fill_in "item[price]", with: "1650"
    choose "予約中"
    find("input[name='item[release_month]']", visible: false).set("2026-11-01")
    click_button "登録する"

    expect(page).to have_content("グッズを登録しました")
    expect(page).to have_content("ヒナタのアクスタ")
    expect(page).to have_content("1,650")

    click_link "編集する"
    fill_in "item[name]", with: "ヒナタのアクスタ(通常版)"
    click_button "保存する"

    expect(page).to have_content("グッズを更新しました")
    expect(page).to have_content("ヒナタのアクスタ(通常版)")

    visit reservations_path
    click_button "支払った"
    expect(page).to have_content("支払い済みにしました")
    click_button "届いた"
    expect(page).to have_content("を所持グッズに移しました")
  end
end
