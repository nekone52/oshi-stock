require "rails_helper"

# #28:推しストックの大事な流れを、人と同じように画面を押してなぞる
# ログイン → 推しを登録 → グッズを登録 → 編集 → 支払った → 届いた
RSpec.describe "推し・グッズの流れ", type: :system do
  let(:user) { create(:user, email_address: "flow@example.com") }

  it "ログインして、推しを登録し、グッズを登録・編集できる" do
    # ログイン画面で、メールアドレスとパスワードを入れて「ログイン」
    visit new_session_path
    fill_in "email_address", with: user.email_address
    fill_in "password", with: "password"
    click_button "ログイン"

    # 推しがまだいないので、最初の画面から「推しを登録する」
    click_link "＋ 推しを登録する"
    fill_in "character[name]", with: "ヒナタ"
    click_button "登録する"

    # 推しキャラ一覧に戻って、登録した推しが並んでいる
    expect(page).to have_current_path(oshis_path)
    expect(page).to have_content("推しを登録しました")
    expect(page).to have_content("ヒナタ")

    # グッズを登録する(推しは今登録したヒナタ、状態は「予約中」)
    visit new_good_path
    fill_in "item[name]", with: "ヒナタのアクスタ"
    select "ヒナタ", from: "item[character_id]"
    fill_in "item[price]", with: "1650"
    choose "予約中"
    click_button "登録する"

    # 登録したグッズの詳細に移って、中身が出ている
    expect(page).to have_content("グッズを登録しました")
    expect(page).to have_content("ヒナタのアクスタ")
    expect(page).to have_content("1,650")

    # 詳細から「編集する」で、名前を書きかえる
    click_link "編集する"
    fill_in "item[name]", with: "ヒナタのアクスタ(通常版)"
    click_button "保存する"

    expect(page).to have_content("グッズを更新しました")
    expect(page).to have_content("ヒナタのアクスタ(通常版)")
  end
end
