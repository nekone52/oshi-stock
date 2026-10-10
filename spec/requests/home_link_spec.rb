require "rails_helper"

# 下のメニューがないので、ホーム以外の画面には「← ホーム」を出して、ホームに戻れるようにする
RSpec.describe "← ホーム", type: :request do
  before { sign_in_as(create(:user)) }

  %w[/goods /oshis /reservations /settings /wishlist].each do |path|
    it "#{path} に「← ホーム」があって、ホームへ戻れる" do
      get path

      expect(response.body).to include(%(<span aria-hidden="true">←</span> ホーム), %(href="#{root_path}"))
    end
  end
end
