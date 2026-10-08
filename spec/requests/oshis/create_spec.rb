require "rails_helper"

# 推しキャラの登録の画面と、登録
RSpec.describe "推しキャラの登録", type: :request do
  let(:user) { create(:user) }

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
end
