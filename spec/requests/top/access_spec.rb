require "rails_helper"

RSpec.describe "ホーム画面(入れるか・推しがいないとき)", type: :request do
  let(:user) { create(:user) }
    it "ログインしていないと、ログイン画面へ移る" do
      get root_path
      expect(response).to redirect_to(new_session_path)
    end

    it "推しがいないときは、「まだ推しがいません」を出す" do
      sign_in_as(user)
      get root_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("まだ推しがいません")
    end
end
