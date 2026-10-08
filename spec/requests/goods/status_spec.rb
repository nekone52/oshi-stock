require "rails_helper"

# ホームの「届いた」「支払った」のワンタップの切り替え
RSpec.describe "グッズの届いた・支払った", type: :request do
  let(:user) { create(:user) }

  describe "PATCH /goods/:id/receive(届いた)" do
    let!(:item) { create(:item, character: create(:character, user: user), status: :reserved, paid: false) }

    it "ログインしていないと、変えずにログイン画面へ移る" do
      patch receive_good_path(item)
      expect(response).to redirect_to(new_session_path)
      expect(item.reload).to be_reserved
    end

    it "所持に変えて、支払い済みかどうかはそのまま残す" do
      sign_in_as(user)
      patch receive_good_path(item)
      expect(response).to redirect_to(root_path)

      item.reload
      expect(item).to be_owned
      expect(item.paid).to be(false)
    end

    it "ほかのユーザーのグッズは、変えられない(404)" do
      other_item = create(:item, character: create(:character, user: create(:user)), status: :reserved)

      sign_in_as(user)
      patch receive_good_path(other_item)
      expect(response).to have_http_status(:not_found)
      expect(other_item.reload).to be_reserved
    end
  end

  describe "PATCH /goods/:id/toggle_paid(支払った)" do
    let!(:item) { create(:item, character: create(:character, user: user), status: :reserved, paid: false) }

    it "押すたびに、支払い済み ⇔ 未払い を切り替える" do
      sign_in_as(user)

      patch toggle_paid_good_path(item)
      expect(item.reload.paid).to be(true)

      patch toggle_paid_good_path(item)
      expect(item.reload.paid).to be(false)
    end

    it "押した画面(絞り込み中のホーム)に戻る" do
      sign_in_as(user)
      back_url = "http://www.example.com/?character_id=#{item.character.id}"
      patch toggle_paid_good_path(item), headers: { "HTTP_REFERER" => back_url }
      expect(response).to redirect_to(back_url)
    end

    it "ほかのユーザーのグッズは、変えられない(404)" do
      other_item = create(:item, character: create(:character, user: create(:user)), paid: false)

      sign_in_as(user)
      patch toggle_paid_good_path(other_item)
      expect(response).to have_http_status(:not_found)
      expect(other_item.reload.paid).to be(false)
    end
  end
end
