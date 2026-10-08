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

  describe "GET /goods/:id/edit" do
    let(:character) { create(:character, user: user, name: "ヒナタ") }
    let(:item) { create(:item, character: character, name: "ヒナタのアクスタ", price: 1650) }

    it "ログインしていないと、ログイン画面へ移る" do
      get edit_good_path(item)
      expect(response).to redirect_to(new_session_path)
    end

    it "自分のグッズなら、今の内容が入った編集画面が開ける" do
      sign_in_as(user)
      get edit_good_path(item)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("グッズを編集", 'value="ヒナタのアクスタ"', 'value="1650"', "保存する")
      expect(response.body).to include('name="_method" value="patch"')
    end

    it "ほかのユーザーのグッズは、見つからない(404)" do
      other_item = create(:item, character: create(:character, user: create(:user)))

      sign_in_as(user)
      get edit_good_path(other_item)
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "PATCH /goods/:id" do
    let(:character) { create(:character, user: user) }
    let(:other_character) { create(:character, user: user) }
    let(:item) { create(:item, character: character, name: "ヒナタのアクスタ") }

    it "ログインしていないと、書きかえずにログイン画面へ移る" do
      patch good_path(item), params: { item: { name: "書きかえ", character_id: character.id } }
      expect(response).to redirect_to(new_session_path)
      expect(item.reload.name).to eq("ヒナタのアクスタ")
    end

    context "入力が正しいとき" do
      before { sign_in_as(user) }

      it "名前・推し・カテゴリ・単価を書きかえて、グッズ一覧へ移る" do
        category = user.categories.find_by!(name: "缶バッジ")
        params = { item: { name: "アオイの缶バッジ", character_id: other_character.id, category_id: category.id, price: "550" } }
        patch good_path(item), params: params
        expect(response).to redirect_to(goods_path)

        item.reload
        expect(item.name).to eq("アオイの缶バッジ")
        expect(item.character).to eq(other_character)
        expect(item.category).to eq(category)
        expect(item.price).to eq(550)

        follow_redirect!
        expect(response.body).to include("グッズを更新しました")
      end

      it "画像を選ばなければ、今の画像はそのまま残る" do
        item.image.attach(io: file_fixture("icon.png").open, filename: "icon.png", content_type: "image/png")
        patch good_path(item), params: { item: { name: "書きかえ", character_id: character.id } }
        expect(item.reload.image).to be_attached
      end
    end

    context "入力がまちがっているとき" do
      before { sign_in_as(user) }

      it "書きかえずに、エラーと一緒に編集画面をもう一度出す" do
        patch good_path(item), params: { item: { name: "", character_id: character.id } }
        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include("グッズ名を入力してください")
        expect(item.reload.name).to eq("ヒナタのアクスタ")
      end
    end

    context "ほかのユーザーのものを送ってきたとき" do
      before { sign_in_as(user) }

      it "ほかのユーザーのグッズは、書きかえられない(404)" do
        other_item = create(:item, character: create(:character, user: create(:user)), name: "ほかの人のグッズ")
        patch good_path(other_item), params: { item: { name: "書きかえ" } }
        expect(response).to have_http_status(:not_found)
        expect(other_item.reload.name).to eq("ほかの人のグッズ")
      end

      it "ほかのユーザーの推しに付けかえることはできない" do
        someone_character = create(:character, user: create(:user))
        patch good_path(item), params: { item: { name: "書きかえ", character_id: someone_character.id } }
        expect(response).to have_http_status(:unprocessable_content)
        expect(item.reload.character).to eq(character)
      end
    end
  end

  describe "DELETE /goods/:id" do
    let!(:item) { create(:item, character: create(:character, user: user), name: "ヒナタのアクスタ") }

    it "編集画面に、確認ダイアログ付きの削除ボタンがある" do
      sign_in_as(user)
      get edit_good_path(item)
      expect(response.body).to include("このグッズを削除する", "data-turbo-confirm", 'name="_method" value="delete"')
    end

    it "ログインしていないと、消さずにログイン画面へ移る" do
      expect { delete good_path(item) }.not_to change(Item, :count)
      expect(response).to redirect_to(new_session_path)
    end

    it "自分のグッズを削除して、グッズ一覧へ移る(303)" do
      sign_in_as(user)
      expect { delete good_path(item) }.to change(Item, :count).by(-1)
      expect(response).to have_http_status(:see_other)
      expect(response).to redirect_to(goods_path)

      follow_redirect!
      expect(response.body).to include("グッズを消しました")
    end

    it "ほかのユーザーのグッズは、削除できない(404)" do
      other_item = create(:item, character: create(:character, user: create(:user)))

      sign_in_as(user)
      expect { delete good_path(other_item) }.not_to change(Item, :count)
      expect(response).to have_http_status(:not_found)
    end
  end

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
