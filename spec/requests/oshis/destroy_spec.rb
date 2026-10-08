require "rails_helper"

# 推しキャラの消去の確認画面と、消去
RSpec.describe "推しキャラの消去", type: :request do
  let(:user) { create(:user) }

  describe "GET /oshis/:id/confirm_delete" do
    let(:character) { create(:character, user: user, name: "ヒナタ") }

    it "ログインしていないと、ログイン画面へ移る" do
      get confirm_delete_oshi_path(character)
      expect(response).to redirect_to(new_session_path)
    end

    it "自分の推しなら、名前と消去のボタンがある確認画面が開ける" do
      sign_in_as(user)
      get confirm_delete_oshi_path(character)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("「ヒナタ」を消去します")
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

    it "自分の推しを消去して、一覧へ移る(303)" do
      sign_in_as(user)
      expect { delete oshi_path(character) }.to change(Character, :count).by(-1)
      expect(response).to have_http_status(:see_other)
      expect(response).to redirect_to(oshis_path)

      follow_redirect!
      expect(response.body).to include("推しを消去しました")
    end

    it "ほかのユーザーの推しは、削除できない(404)" do
      other_character = create(:character, user: create(:user))

      sign_in_as(user)
      expect { delete oshi_path(other_character) }.not_to change(Character, :count)
      expect(response).to have_http_status(:not_found)
    end
  end
end
