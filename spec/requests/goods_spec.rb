require "rails_helper"

RSpec.describe "グッズ", type: :request do
  let(:user) { create(:user) }

  describe "GET /goods/new" do
    it "ログインしていないと、ログイン画面へ移る" do
      get new_good_path
      expect(response).to redirect_to(new_session_path)
    end

    it "推しがいないときは、先に推しを追加するように案内する" do
      sign_in_as(user)
      get new_good_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("まだ推しがいません")
    end

    it "自分の推しとカテゴリだけを選択肢に出す" do
      create(:character, user: user, name: "ヒナタ")
      create(:category, user: user, name: "自分のカテゴリ")
      other_user = create(:user)
      create(:character, user: other_user, name: "ほかの人の推し")
      create(:category, user: other_user, name: "ほかの人のカテゴリ")

      sign_in_as(user)
      get new_good_path
      expect(response.body).to include("ヒナタ", "自分のカテゴリ", "アクスタ")
      expect(response.body).not_to include("ほかの人の推し")
      expect(response.body).not_to include("ほかの人のカテゴリ")
    end
  end

  describe "POST /goods" do
    let(:character) { create(:character, user: user) }
    let(:category) { user.categories.find_by!(name: "アクスタ") }

    it "ログインしていないと、グッズは作られずログイン画面へ移る" do
      expect { post goods_path, params: { item: { name: "アクスタ", character_id: character.id } } }.not_to change(Item, :count)
      expect(response).to redirect_to(new_session_path)
    end

    context "入力が正しいとき" do
      before { sign_in_as(user) }

      it "選んだ推しのグッズとして保存し、グッズ一覧へ移る" do
        params = { item: { name: "ヒナタのアクスタ", character_id: character.id, category_id: category.id,
                           url: "https://example.com/goods/1", shop_name: "公式ショップ", price: "1650", quantity: "2",
                           status: "reserved", paid: "1", release_month: "2026-10-01", release_period: "上旬",
                           payment_deadline: "2026-10-20", memo: "特典付き",
                           image: fixture_file_upload("icon.png", "image/png") } }
        expect { post goods_path, params: params }.to change(character.items, :count).by(1)
        expect(response).to redirect_to(goods_path)

        item = character.items.last
        expect(item.name).to eq("ヒナタのアクスタ")
        expect(item.category).to eq(category)
        expect(item.price).to eq(1650)
        expect(item.quantity).to eq(2)
        expect(item).to be_reserved
        expect(item.paid).to be(true)
        expect(item.release_month).to eq(Date.new(2026, 10, 1))
        expect(item.payment_deadline).to eq(Date.new(2026, 10, 20))
        expect(item.image).to be_attached

        follow_redirect!
        expect(response.body).to include("グッズを登録しました")
      end

      it "カテゴリを選ばなくても保存できる" do
        post goods_path, params: { item: { name: "ヒナタのアクスタ", character_id: character.id, category_id: "" } }
        expect(Item.last.category).to be_nil
      end
    end

    context "入力がまちがっているとき" do
      before { sign_in_as(user) }

      it "グッズは作られず、エラーと一緒に画面をもう一度出す" do
        expect { post goods_path, params: { item: { name: "", character_id: "", quantity: "" } } }.not_to change(Item, :count)
        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include("グッズ名を入力してください", "推しキャラを入力してください", "個数を入力してください")
      end

      it "GIF の画像では登録できない" do
        params = { item: { name: "ヒナタのアクスタ", character_id: character.id, image: fixture_file_upload("icon.gif", "image/gif") } }
        expect { post goods_path, params: params }.not_to change(Item, :count)
        expect(response.body).to include("商品画像は JPEG, PNG, WebP 形式にしてください")
      end
    end

    context "ほかのユーザーのものを送ってきたとき" do
      before { sign_in_as(user) }

      it "ほかのユーザーの推しを選んでも、グッズは作られない" do
        other_character = create(:character, user: create(:user))
        expect { post goods_path, params: { item: { name: "ヒナタのアクスタ", character_id: other_character.id } } }.not_to change(Item, :count)
        expect(response).to have_http_status(:unprocessable_content)
      end

      it "ほかのユーザーのカテゴリを選んでも、カテゴリはつながらない" do
        other_category = create(:category, user: create(:user))
        post goods_path, params: { item: { name: "ヒナタのアクスタ", character_id: character.id, category_id: other_category.id } }
        expect(Item.last.category).to be_nil
      end
    end
  end
end
