require "rails_helper"

RSpec.describe "新規登録", type: :request do
  describe "GET /registration/new" do
    it "ログインしていなくても、新規登録の画面が開ける" do
      get new_registration_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("新規登録")
    end
  end

  describe "POST /registration" do
    let(:valid_params) do
      { user: { email_address: "new@example.com", password: "password", password_confirmation: "password" } }
    end

    context "入力が正しいとき" do
      it "ユーザーが作られ、ログインした状態でホームへ移る" do
        expect { post registration_path, params: valid_params }.to change(User, :count).by(1)
        expect(response).to redirect_to(root_path)

        follow_redirect!
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("アカウントを登録しました。")
      end
    end

    context "入力がまちがっているとき" do
      it "ユーザーは作られず、エラーと一緒に画面をもう一度出す" do
        params = { user: { email_address: "", password: "short", password_confirmation: "short" } }
        expect { post registration_path, params: params }.not_to change(User, :count)
        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include("メールアドレスを入力してください")
        expect(response.body).to include("パスワードは8文字以上で入力してください")
      end

      it "すでに登録されているメールアドレスでは登録できない" do
        create(:user, email_address: "new@example.com")
        expect { post registration_path, params: valid_params }.not_to change(User, :count)
        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include("メールアドレスはすでに存在します")
      end
    end
  end
end
