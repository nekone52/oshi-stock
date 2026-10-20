require "rails_helper"

RSpec.describe "OGP(リンクを貼ったときのカード)", type: :request do
  # SNS はログインしないで見に来るので、ログインしていない画面で確かめる
  it "ログイン画面の <head> に、タイトル・説明・画像の帯がある" do
    get new_session_path

    expect(response.body).to include(
      %(<meta property="og:title" content="推しストック">),
      %(<meta property="og:description" content="推し活グッズの持ち物・予約・ほしい物を、まとめて管理できるアプリ">),
      %(<meta property="og:image" content="http://www.example.com/ogp.png">),
      %(<meta name="twitter:card" content="summary_large_image">)
    )
  end

  it "帯に書いた画像(public/ogp.png)を取りに来られる" do
    get "/ogp.png"

    expect(response).to have_http_status(:ok)
    expect(response.media_type).to eq("image/png")
  end
end
