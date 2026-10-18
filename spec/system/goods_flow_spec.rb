require "rails_helper"

# #28:推しストックの大事な流れを、人と同じように画面を押してなぞる
# ログイン → 推しを登録 → グッズを登録 → 編集 → 支払った → 届いた
RSpec.describe "推し・グッズの流れ", type: :system do
  let(:user) { create(:user, email_address: "flow@example.com") }

  it "ログインして、推しを登録できる" do
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
  end
end
