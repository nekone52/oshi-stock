require "rails_helper"

# 利用規約・プライバシーの「<」の行き先(#148)
# ブラウザの戻る(JS)はリクエストスペックでは動かないので、「<」のリンクの形を確かめる
RSpec.describe "利用規約・プライバシーの「<」", type: :request do
  it "新規登録の画面のリンクに、新規登録から来た付せん(from=signup)がついている" do
    get signup_path

    expect(response.body).to include('href="/terms?from=signup"')
    expect(response.body).to include('href="/privacy?from=signup"')
  end

  {
    "利用規約" => "/terms",
    "プライバシーポリシー" => "/privacy"
  }.each do |title, path|
    it "新規登録から来たときは、「<」が新規登録にもどる(#{title})" do
      get path, params: { from: "signup" }

      back_link = response.parsed_body.at_css('a[aria-label="戻る"]')
      expect(back_link["href"]).to eq(signup_path)
      expect(back_link["data-controller"]).to eq("history-back")
    end

    it "設定から来たときは、今までどおり「<」が設定画面にもどる(#{title})" do
      sign_in_as(create(:user))
      get path

      back_link = response.parsed_body.at_css('a[aria-label="戻る"]')
      expect(back_link["href"]).to eq(settings_path)
      expect(back_link["data-controller"]).to be_nil
    end
  end
end
