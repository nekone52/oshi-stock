require "rails_helper"

RSpec.describe "カテゴリ", type: :request do
  let(:user) { create(:user) }
  # Turbo Stream で返してほしいときの送り方(画面を移らずに、その場で書きかえる)
  let(:turbo_stream_headers) { { "Accept" => "text/vnd.turbo-stream.html, text/html" } }

  describe "POST /categories" do
    it "ログインしていないと、カテゴリは作られずログイン画面へ移る" do
      expect { post categories_path, params: { category: { name: "うちわ" } } }.not_to change(Category, :count)
      expect(response).to redirect_to(new_session_path)
    end

    context "ログインしているとき" do
      before { sign_in_as(user) }

      it "自分のカテゴリとして追加し、チップとシートの行を足す指示を返す" do
        expect {
          post categories_path, params: { category: { name: "うちわ" } }, headers: turbo_stream_headers
        }.to change(user.categories, :count).by(1)

        expect(response.media_type).to eq("text/vnd.turbo-stream.html")
        expect(response.body).to include('action="append" target="category_chips"')
        expect(response.body).to include('action="append" target="category_rows"')
        expect(response.body).to include("うちわ")
      end

      it "同じ名前のカテゴリは追加できず、シートにエラーを出す" do
        expect {
          post categories_path, params: { category: { name: "アクスタ" } }, headers: turbo_stream_headers
        }.not_to change(Category, :count)

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include('target="category_errors"', "カテゴリ名はすでに存在します")
      end

      it "空の名前では追加できない" do
        expect {
          post categories_path, params: { category: { name: "" } }, headers: turbo_stream_headers
        }.not_to change(Category, :count)
        expect(response.body).to include("カテゴリ名を入力してください")
      end
    end
  end

  describe "DELETE /categories/:id" do
    let!(:category) { create(:category, user: user, name: "うちわ") }

    it "ログインしていないと、消さずにログイン画面へ移る" do
      expect { delete category_path(category) }.not_to change(Category, :count)
      expect(response).to redirect_to(new_session_path)
    end

    context "ログインしているとき" do
      before { sign_in_as(user) }

      it "自分のカテゴリを消して、チップとシートの行を消す指示を返す" do
        expect { delete category_path(category), headers: turbo_stream_headers }.to change(Category, :count).by(-1)
        expect(response.body).to include("action=\"remove\" target=\"chip_category_#{category.id}\"")
        expect(response.body).to include("action=\"remove\" target=\"category_#{category.id}\"")
      end

      it "カテゴリを消しても、グッズは残してカテゴリだけ空にする" do
        item = create(:item, character: create(:character, user: user), category: category)
        expect { delete category_path(category), headers: turbo_stream_headers }.not_to change(Item, :count)
        expect(item.reload.category).to be_nil
      end

      it "ほかのユーザーのカテゴリは、消せない(404)" do
        other_category = create(:category, user: create(:user))
        expect { delete category_path(other_category), headers: turbo_stream_headers }.not_to change(Category, :count)
        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
