require "rails_helper"

# 推しキャラの編集の画面と、保存
RSpec.describe "推しキャラの編集", type: :request do
  let(:user) { create(:user) }

  describe "GET /oshis/:id/edit" do
    let(:character) { create(:character, user: user, name: "ヒナタ", color: "#2F5DAA") }

    it "ログインしていないと、ログイン画面へ移る" do
      get edit_oshi_path(character)
      expect(response).to redirect_to(new_session_path)
    end

    it "自分の推しなら、今の名前と色が入った編集画面が開ける" do
      sign_in_as(user)
      get edit_oshi_path(character)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("推しを編集")
      expect(response.body).to include('value="ヒナタ"')
      expect(response.body).to include('value="#2F5DAA"')
    end

    it "ほかのユーザーの推しは、見つからない(404)" do
      other_character = create(:character, user: create(:user))

      sign_in_as(user)
      get edit_oshi_path(other_character)
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "PATCH /oshis/:id" do
    let(:character) { create(:character, user: user, name: "ヒナタ", color: "#2F5DAA") }

    it "ログインしていないと、書きかえずにログイン画面へ移る" do
      patch oshi_path(character), params: { character: { name: "アオイ" } }
      expect(response).to redirect_to(new_session_path)
      expect(character.reload.name).to eq("ヒナタ")
    end

    context "入力が正しいとき" do
      before { sign_in_as(user) }

      it "名前・色・アイコンを書きかえて、一覧へ移る" do
        params = { character: { name: "アオイ", color: "#445566", icon: fixture_file_upload("icon.png", "image/png") } }
        patch oshi_path(character), params: params
        expect(response).to redirect_to(oshis_path)

        character.reload
        expect(character.name).to eq("アオイ")
        expect(character.color).to eq("#445566")
        expect(character.icon).to be_attached

        follow_redirect!
        expect(response.body).to include("推しを更新しました")
      end

      it "ほかのユーザーの番号(user_id)を送っても、持ち主は変わらない" do
        patch oshi_path(character), params: { character: { name: "アオイ", user_id: create(:user).id } }
        expect(character.reload.user).to eq(user)
      end
    end

    context "入力がまちがっているとき" do
      before { sign_in_as(user) }

      it "書きかえずに、エラーと一緒に編集画面をもう一度出す" do
        patch oshi_path(character), params: { character: { name: "" } }
        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include("推しキャラ名を入力してください")
        expect(character.reload.name).to eq("ヒナタ")
      end

      it "GIF の画像では書きかえられない" do
        patch oshi_path(character), params: { character: { name: "アオイ", icon: fixture_file_upload("icon.gif", "image/gif") } }
        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include("アイコン画像は JPEG, PNG, WebP 形式にしてください")
        expect(character.reload.name).to eq("ヒナタ")
      end
    end

    it "ほかのユーザーの推しは、書きかえられない(404)" do
      other_character = create(:character, user: create(:user), name: "ほかの人の推し")

      sign_in_as(user)
      patch oshi_path(other_character), params: { character: { name: "書きかえ" } }
      expect(response).to have_http_status(:not_found)
      expect(other_character.reload.name).to eq("ほかの人の推し")
    end
  end
end
