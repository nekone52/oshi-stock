require "rails_helper"

# グッズの編集の画面と、保存
RSpec.describe "グッズの編集", type: :request do
  let(:user) { create(:user) }

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

    it "支払期限と発売月は、大きいボタンの係と、保存ずみの値が入った見えない入力で出る(#94)" do
      item.update!(payment_deadline: Date.new(2026, 10, 14), release_month: Date.new(2026, 11, 1))
      sign_in_as(user)
      get edit_good_path(item)

      body = response.body
      expect(body).to include('data-controller="deadline-picker"', 'data-controller="month-picker"')
      # 属性の並び順に関係なく、その入力のタグを1つ取り出してから、中身を確かめる
      deadline_input = body[/<input[^>]*name="item\[payment_deadline\]"[^>]*>/]
      month_input = body[/<input[^>]*name="item\[release_month\]"[^>]*>/]
      expect(deadline_input).to include('type="hidden"', 'value="2026-10-14"')
      expect(month_input).to include('type="hidden"', 'value="2026-11-01"')
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

      it "名前・推し・カテゴリ・単価を書きかえて、そのグッズの詳細へ戻る" do
        category = user.categories.find_by!(name: "缶バッジ")
        params = { item: { name: "アオイの缶バッジ", character_id: other_character.id, category_id: category.id, price: "550" } }
        patch good_path(item), params: params
        expect(response).to redirect_to(good_path(item))

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
end
