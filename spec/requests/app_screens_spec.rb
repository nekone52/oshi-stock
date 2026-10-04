require "rails_helper"

RSpec.describe "App screens (mock)", type: :request do
  {
    "予約注文" => "/reservations",
    "予約を登録" => "/reservations/new",
    "所持グッズ" => "/goods",
    "グッズを登録" => "/goods/new",
    "ほしい物を追加" => "/wishlist",
    "設定" => "/settings"
  }.each do |title, path|
    it "#{title} が表示される(#{path})" do
      get path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(title)
    end
  end
end
