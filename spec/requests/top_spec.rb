require "rails_helper"

RSpec.describe "Top", type: :request do
  describe "GET /" do
    it "ログインしていないと、ログイン画面へ移る" do
      get root_path
      expect(response).to redirect_to(new_session_path)
    end

    it "ログインしていれば、トップページが表示される" do
      sign_in_as(create(:user))
      get root_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("推しストック")
    end
  end
end
