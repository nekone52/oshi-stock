require "rails_helper"

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

    it "お祝いのお知らせ(celebrate)になり、マスコットがぽよんと出る(#92)" do
      sign_in_as(user)
      patch receive_good_path(item)
      expect(flash[:celebrate]).to eq("「#{item.name}」を所持グッズに移しました")

      follow_redirect!
      expect(response.body).to include("mascot_", "motion-safe:animate-poyon")
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

    it "支払い済みにしたときだけ、お祝いのお知らせ(celebrate)になる(#92)" do
      sign_in_as(user)

      patch toggle_paid_good_path(item)
      expect(flash[:celebrate]).to eq("支払い済みにしました")
      follow_redirect!
      expect(response.body).to include("mascot_", "motion-safe:animate-poyon")
    end

    it "未払いに戻したときは、ふつうのお知らせ(notice)。マスコットもぽよんも出ない(#92)" do
      item.update!(paid: true)
      sign_in_as(user)

      patch toggle_paid_good_path(item)
      expect(flash[:notice]).to eq("未払いに戻しました")
      expect(flash[:celebrate]).to be_nil
      follow_redirect!
      expect(response.body).to include("未払いに戻しました")
      expect(response.body).not_to include("mascot_", "motion-safe:animate-poyon")
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
