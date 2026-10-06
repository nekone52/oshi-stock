require "rails_helper"

RSpec.describe "推しキャラ", type: :request do
  let(:user) { create(:user) }

  describe "GET /oshis" do
    it "ログインしていないと、ログイン画面へ移る" do
      get oshis_path
      expect(response).to redirect_to(new_session_path)
    end

    it "推しがいないときは、「まだ推しがいません」を出す" do
      sign_in_as(user)
      get oshis_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("まだ推しがいません")
    end

    it "自分の推しだけを表示し、ほかのユーザーの推しは表示しない" do
      create(:character, user: user, name: "ヒナタ")
      create(:character, user: create(:user), name: "ほかの人の推し")

      sign_in_as(user)
      get oshis_path
      expect(response.body).to include("ヒナタ")
      expect(response.body).not_to include("ほかの人の推し")
    end

    it "「…」メニューに、その推しの編集と削除のリンクがある" do
      character = create(:character, user: user)

      sign_in_as(user)
      get oshis_path
      expect(response.body).to include(edit_oshi_path(character))
      expect(response.body).to include(confirm_delete_oshi_path(character))
    end
  end

  describe "GET /oshis/new" do
    it "ログインしていれば、推しを追加の画面が開ける" do
      sign_in_as(user)
      get new_oshi_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("推しを追加")
    end
  end

  describe "POST /oshis" do
    it "ログインしていないと、推しは作られずログイン画面へ移る" do
      expect { post oshis_path, params: { character: { name: "ヒナタ" } } }.not_to change(Character, :count)
      expect(response).to redirect_to(new_session_path)
    end

    context "入力が正しいとき" do
      before { sign_in_as(user) }

      it "ログイン中のユーザーの推しとして保存し、一覧へ移る" do
        params = { character: { name: "ヒナタ", color: "#112233", icon: fixture_file_upload("icon.png", "image/png") } }
        expect { post oshis_path, params: params }.to change(user.characters, :count).by(1)
        expect(response).to redirect_to(oshis_path)

        character = user.characters.last
        expect(character.name).to eq("ヒナタ")
        expect(character.color).to eq("#112233")
        expect(character.icon).to be_attached

        follow_redirect!
        expect(response.body).to include("推しを登録しました！")
      end

      it "ほかのユーザーの番号(user_id)を送っても、ログイン中のユーザーの推しになる" do
        other = create(:user)
        post oshis_path, params: { character: { name: "ヒナタ", user_id: other.id } }
        expect(Character.last.user).to eq(user)
      end
    end

    context "入力がまちがっているとき" do
      before { sign_in_as(user) }

      it "推しは作られず、エラーと一緒に画面をもう一度出す" do
        expect { post oshis_path, params: { character: { name: "" } } }.not_to change(Character, :count)
        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include("推しキャラ名を入力してください")
      end

      it "GIF の画像では登録できない" do
        params = { character: { name: "ヒナタ", icon: fixture_file_upload("icon.gif", "image/gif") } }
        expect { post oshis_path, params: params }.not_to change(Character, :count)
        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include("アイコン画像は JPEG, PNG, WebP 形式にしてください")
      end
    end
  end

  describe "GET /oshis/:id/edit" do
    let(:character) { create(:character, user: user, name: "ヒナタ", color: "#112233") }

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
      expect(response.body).to include('value="#112233"')
    end

    it "ほかのユーザーの推しは、見つからない(404)" do
      other_character = create(:character, user: create(:user))

      sign_in_as(user)
      get edit_oshi_path(other_character)
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "PATCH /oshis/:id" do
    let(:character) { create(:character, user: user, name: "ヒナタ", color: "#112233") }

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

  describe "GET /oshis/:id/confirm_delete" do
    let(:character) { create(:character, user: user, name: "ヒナタ") }

    it "ログインしていないと、ログイン画面へ移る" do
      get confirm_delete_oshi_path(character)
      expect(response).to redirect_to(new_session_path)
    end

    it "自分の推しなら、名前と削除のボタンがある確認画面が開ける" do
      sign_in_as(user)
      get confirm_delete_oshi_path(character)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("「ヒナタ」を削除します")
      expect(response.body).to include('name="_method" value="delete"')
    end

    it "ほかのユーザーの推しは、見つからない(404)" do
      other_character = create(:character, user: create(:user))

      sign_in_as(user)
      get confirm_delete_oshi_path(other_character)
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "DELETE /oshis/:id" do
    let!(:character) { create(:character, user: user) }

    it "ログインしていないと、消さずにログイン画面へ移る" do
      expect { delete oshi_path(character) }.not_to change(Character, :count)
      expect(response).to redirect_to(new_session_path)
    end

    it "自分の推しを削除して、一覧へ移る(303)" do
      sign_in_as(user)
      expect { delete oshi_path(character) }.to change(Character, :count).by(-1)
      expect(response).to have_http_status(:see_other)
      expect(response).to redirect_to(oshis_path)

      follow_redirect!
      expect(response.body).to include("推しを削除しました")
    end

    it "ほかのユーザーの推しは、削除できない(404)" do
      other_character = create(:character, user: create(:user))

      sign_in_as(user)
      expect { delete oshi_path(other_character) }.not_to change(Character, :count)
      expect(response).to have_http_status(:not_found)
    end
  end
end
