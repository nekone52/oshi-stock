require "rails_helper"

RSpec.describe "App screens (mock)", type: :request do
  {
    "グッズを登録" => "/goods/new",
    "設定" => "/settings",
    "推しキャラ" => "/oshis",
    "推しを追加" => "/oshis/new",
    "退会しますか？" => "/settings/withdraw",
    "まだ推しがいません" => "/start"
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
