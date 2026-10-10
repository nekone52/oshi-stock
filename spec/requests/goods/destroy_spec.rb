require "rails_helper"

# グッズの消去
RSpec.describe "グッズの消去", type: :request do
  let(:user) { create(:user) }

  describe "DELETE /goods/:id" do
    let!(:item) { create(:item, character: create(:character, user: user), name: "ヒナタのアクスタ") }

    it "編集画面に、確認ダイアログ付きの消去ボタンがある" do
      sign_in_as(user)
      get edit_good_path(item)
      expect(response.body).to include("このグッズを消去する", "data-turbo-confirm", 'name="_method" value="delete"')
    end

    it "ログインしていないと、消さずにログイン画面へ移る" do
      expect { delete good_path(item) }.not_to change(Item, :count)
      expect(response).to redirect_to(new_session_path)
    end

    # 消去のあとは、グッズの状態で決めた一覧へ(詳細の「<」と同じ。くわしい分け方は spec/helpers/items_helper_spec.rb)
    it "自分のほしい物を消去して、グッズ一覧(ほしい物)へ移る(303)" do
      sign_in_as(user)
      expect { delete good_path(item) }.to change(Item, :count).by(-1)
      expect(response).to have_http_status(:see_other)
      expect(response).to redirect_to(goods_path(status: "wanted"))

      follow_redirect!
      expect(response.body).to include("グッズを消去しました")
    end

    it "予約中のグッズを消去すると、予約画面へ移る" do
      reserved_item = create(:item, character: item.character, status: :reserved)

      sign_in_as(user)
      delete good_path(reserved_item)
      expect(response).to redirect_to(reservations_path)
    end

    it "ほかのユーザーのグッズは、削除できない(404)" do
      other_item = create(:item, character: create(:character, user: create(:user)))

      sign_in_as(user)
      expect { delete good_path(other_item) }.not_to change(Item, :count)
      expect(response).to have_http_status(:not_found)
    end
  end
end
