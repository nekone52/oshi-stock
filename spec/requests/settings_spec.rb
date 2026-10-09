require "rails_helper"

# 設定画面の「テーマの色」の保存と、アプリ全体への反映
RSpec.describe "テーマの色の保存", type: :request do
  let(:user) { create(:user) }

  describe "GET /settings" do
    it "推しの色(おすすめ)の9色が、名前つきで並んでいる" do
      sign_in_as(user)
      get settings_path

      expect(response.body).to include("推しの色(おすすめ)")
      ThemeHelper::THEME_SWATCHES.each do |name, color|
        expect(response.body).to include(%(data-color="#{color}"), name)
      end
      expect(response.body.scan('data-theme-picker-target="swatch"').size).to eq(9)
    end

    it "今のテーマの色が、カラーピッカーに入っている" do
      user.update!(theme_color: "#4E6FA3")
      sign_in_as(user)
      get settings_path

      # color_field は、ブラウザの決まりに合わせて色を小文字で出す
      expect(response.body).to include('value="#4e6fa3"')
    end
  end

  describe "PATCH /settings" do
    it "ログインしていないと、ログイン画面へ移る" do
      patch settings_path, params: { user: { theme_color: "#4E6FA3" } }
      expect(response).to redirect_to(new_session_path)
    end

    it "色を選んで保存すると、自分の色が変わって、設定画面に戻る" do
      sign_in_as(user)
      patch settings_path, params: { user: { theme_color: "#4E6FA3" } }

      expect(user.reload.theme_color).to eq("#4E6FA3")
      expect(response).to redirect_to(settings_path)
      expect(flash[:notice]).to eq("テーマの色を変えました")
    end

    it "色の形でなければ保存されず、設定画面にエラーが出る" do
      sign_in_as(user)
      patch settings_path, params: { user: { theme_color: "red" } }

      expect(user.reload.theme_color).to eq("#E8577A")
      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("テーマの色は不正な値です")
    end

    it "ほかの人の色は変わらない(ユーザーの番号を送っても、本人の色だけが変わる)" do
      other = create(:user)
      sign_in_as(user)
      patch settings_path, params: { id: other.id, user: { theme_color: "#4E6FA3", id: other.id } }

      expect(other.reload.theme_color).to eq("#E8577A")
      expect(user.reload.theme_color).to eq("#4E6FA3")
    end
  end

  describe "アプリ全体への反映" do
    it "保存した色が、ほかの画面(ホーム)でも、ボタンの色の入れ物に入っている" do
      user.update!(theme_color: "#4E6FA3")
      sign_in_as(user)
      get root_path

      expect(response.body).to include("--color-accent: #4E6FA3")
    end

    it "最初のピンクのままなら、色の入れ物は上書きしない(application.css の色をそのまま使う)" do
      sign_in_as(user)
      get root_path

      expect(response.body).not_to include("--color-accent:")
    end
  end
end
