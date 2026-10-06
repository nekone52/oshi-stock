require "rails_helper"

RSpec.describe "App screens (mock)", type: :request do
  # ログインが必要な画面(まだモック)
  {
    "予約注文" => "/reservations",
    "予約を登録" => "/reservations/new",
    "所持グッズ" => "/goods",
    "グッズを登録" => "/goods/new",
    "ほしい物を追加" => "/wishlist",
    "追加する" => "/wishlist/new",
    "設定" => "/settings",
    "推しキャラ" => "/oshis",
    "推しを追加" => "/oshis/new",
    "ヒナタのグッズ" => "/oshis/1",
    "削除しますか？" => "/oshis/1/confirm_delete",
    "退会しますか？" => "/settings/withdraw",
    "グッズを編集" => "/goods/1/edit",
    "まだ推しがいません" => "/start",
    "カテゴリを追加" => "/categories/new"
  }.each do |title, path|
    it "ログインしていないと、ログイン画面へ移る(#{path})" do
      get path
      expect(response).to redirect_to(new_session_path)
    end

    it "ログインしていれば、#{title} が表示される(#{path})" do
      sign_in_as(create(:user))
      get path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(title)
    end
  end

  # ログインしなくても開ける画面
  {
    "新規登録" => "/signup",
    "利用規約" => "/terms",
    "プライバシーポリシー" => "/privacy"
  }.each do |title, path|
    it "ログインしていなくても、#{title} が表示される(#{path})" do
      get path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(title)
    end
  end
end
