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

  describe "退会" do
    describe "GET /settings/withdraw" do
      it "確認画面に、退会する(DELETE /settings/withdraw)ボタンがある" do
        sign_in_as(user)
        get withdraw_path

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("退会しますか？")
        expect(response.body).to include('action="/settings/withdraw"', 'name="_method" value="delete"')
      end
    end

    describe "DELETE /settings/withdraw" do
      it "ログインしていないと、ログイン画面へ移る(だれも消えない)" do
        user
        expect { delete withdraw_path }.not_to change(User, :count)
        expect(response).to redirect_to(new_session_path)
      end

      it "退会すると、ユーザーと、推し・グッズ・カテゴリ・ログインの記録・画像がまとめて消える" do
        character = create(:character, user: user)
        character.icon.attach(io: file_fixture("icon.png").open, filename: "icon.png", content_type: "image/png")
        create(:item, character: character)
        sign_in_as(user)

        expect { delete withdraw_path }
          .to change(User, :count).by(-1)
          .and change(Character, :count).by(-1)
          .and change(Item, :count).by(-1)
          .and change(Category, :count).by(-5) # 最初の5つのカテゴリ
          .and change(Session, :count).by(-1)
          .and change(ActiveStorage::Attachment, :count).by(-1)
      end

      it "退会したら、ログイン画面に戻ってお知らせが出て、そのあとはログアウトの状態になる" do
        sign_in_as(user)
        delete withdraw_path

        expect(response).to redirect_to(new_session_path)
        expect(flash[:notice]).to eq("退会しました。ご利用ありがとうございました")

        # ホームを開こうとしても、ログイン画面へ移る(ログインの鍵も消えている)
        get root_path
        expect(response).to redirect_to(new_session_path)
      end

      it "ほかの人のアカウントとデータは消えない" do
        other = create(:user)
        create(:character, user: other)
        sign_in_as(user)

        expect { delete withdraw_path }.not_to change { other.characters.count }
        expect(User.exists?(other.id)).to be(true)
      end
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
