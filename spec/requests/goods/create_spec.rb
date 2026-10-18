require "rails_helper"

# グッズの登録の画面と、登録(ダブり買いの警告もふくむ)
RSpec.describe "グッズの登録", type: :request do
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

      it "選んだ推しのグッズとして保存し、そのグッズの詳細へ移る" do
        params = { item: { name: "ヒナタのアクスタ", character_id: character.id, category_id: category.id,
                           url: "https://example.com/goods/1", shop_name: "公式ショップ", price: "1650", quantity: "2",
                           status: "reserved", paid: "1", release_month: "2026-10-01", release_period: "上旬",
                           payment_deadline: "2026-10-20", memo: "特典付き",
                           image: fixture_file_upload("icon.png", "image/png") } }
        expect { post goods_path, params: params }.to change(character.items, :count).by(1)

        item = character.items.last
        expect(response).to redirect_to(good_path(item))
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
        # 形式がだめな画像は、棚にしまわない(引換券も出さない)
        expect(response.body).not_to include('name="kept_image"')
      end

      it "名前が空のエラーのあとも、選んだ画像は引きつがれる" do
        post goods_path, params: { item: { name: "", character_id: character.id, image: fixture_file_upload("icon.png", "image/png") } }
        expect(response).to have_http_status(:unprocessable_content)
        kept_image = response.body[/name="kept_image"[^>]*value="([^"]+)"/, 1]
        expect(kept_image).to be_present

        params = { item: { name: "ヒナタのアクスタ", character_id: character.id }, kept_image: kept_image }
        expect { post goods_path, params: params }.to change(Item, :count).by(1)
        expect(Item.last.image).to be_attached
      end
    end

    context "同じ名前のグッズがすでにあるとき(ダブり買いの警告)" do
      before do
        create(:item, character: character, name: "ヒナタのアクスタ", status: :owned)
        sign_in_as(user)
      end

      it "保存せずに、警告と一緒に登録画面をもう一度出す" do
        params = { item: { name: "ヒナタのアクスタ", character_id: character.id } }
        expect { post goods_path, params: params }.not_to change(Item, :count)

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include("同じ名前のグッズがあります", "所持", "それでも登録する")
        # 入力した名前は残っている
        expect(response.body).to include('value="ヒナタのアクスタ"')
      end

      it "「それでも登録する」を押すと、そのまま保存する(布教用・保存用)" do
        params = { item: { name: "ヒナタのアクスタ", character_id: character.id }, confirm_duplicate: "1" }
        expect { post goods_path, params: params }.to change(Item, :count).by(1)
        expect(response).to redirect_to(good_path(Item.last))
      end

      # Codex の指摘:画像を選んで警告が出たあと「それでも登録する」を押すと、画像なしで登録されていた
      it "画像を選んで警告が出ても、「それでも登録する」で画像つきで保存される(引換券で引きつぐ)" do
        post goods_path, params: { item: { name: "ヒナタのアクスタ", character_id: character.id, image: fixture_file_upload("icon.png", "image/png") } }
        expect(response).to have_http_status(:unprocessable_content)
        # 警告の画面のフォームに、しまった画像の引換券(kept_image)が入っている
        kept_image = response.body[/name="kept_image"[^>]*value="([^"]+)"/, 1]
        expect(kept_image).to be_present

        # 2回目は画像を選ばずに、引換券だけで送る(ブラウザは画像の欄を空っぽにするため)
        params = { item: { name: "ヒナタのアクスタ", character_id: character.id }, kept_image: kept_image, confirm_duplicate: "1" }
        expect { post goods_path, params: params }.to change(Item, :count).by(1)
        expect(Item.last.image).to be_attached
        expect(Item.last.image.filename.to_s).to eq("icon.png")
      end

      it "書きかえた引換券では、画像はつかない(ほかの人の画像は取り出せない)" do
        params = { item: { name: "ヒナタのアクスタ", character_id: character.id }, kept_image: "kakikaeta-hikikaeken", confirm_duplicate: "1" }
        expect { post goods_path, params: params }.to change(Item, :count).by(1)
        expect(Item.last.image).not_to be_attached
      end

      # Codex の指摘①:サインが本物でも、本人用でなければ使えないようにする
      it "ほかの人用の引換券では、画像はつかない" do
        other = create(:user)
        blob = ActiveStorage::Blob.create_and_upload!(io: file_fixture("icon.png").open, filename: "icon.png", content_type: "image/png")
        others_ticket = blob.signed_id(purpose: "kept_image_for_user_#{other.id}", expires_in: 1.hour)

        params = { item: { name: "ヒナタのアクスタ", character_id: character.id }, kept_image: others_ticket, confirm_duplicate: "1" }
        expect { post goods_path, params: params }.to change(Item, :count).by(1)
        expect(Item.last.image).not_to be_attached
      end

      it "画像の URL に入っている番号(ほかのグッズについている画像)では、画像はつかない" do
        others_item = create(:item, character: create(:character, user: create(:user)))
        others_item.image.attach(io: file_fixture("icon.png").open, filename: "icon.png", content_type: "image/png")

        params = { item: { name: "ヒナタのアクスタ", character_id: character.id }, kept_image: others_item.image.blob.signed_id, confirm_duplicate: "1" }
        expect { post goods_path, params: params }.to change(Item, :count).by(1)
        expect(Item.last.image).not_to be_attached
        expect(others_item.reload.image).to be_attached
      end

      # travel(時間を進める道具)を使えるようにする
      include ActiveSupport::Testing::TimeHelpers

      it "1時間より前の引換券は、時間切れで使えない" do
        post goods_path, params: { item: { name: "ヒナタのアクスタ", character_id: character.id, image: fixture_file_upload("icon.png", "image/png") } }
        kept_image = response.body[/name="kept_image"[^>]*value="([^"]+)"/, 1]

        travel 2.hours do
          params = { item: { name: "ヒナタのアクスタ", character_id: character.id }, kept_image: kept_image, confirm_duplicate: "1" }
          expect { post goods_path, params: params }.to change(Item, :count).by(1)
          expect(Item.last.image).not_to be_attached
        end
      end

      it "ほかのユーザーの同じ名前のグッズは、関係ない(警告を出さない)" do
        create(:item, character: create(:character, user: create(:user)), name: "アオイの缶バッジ")
        params = { item: { name: "アオイの缶バッジ", character_id: character.id } }
        expect { post goods_path, params: params }.to change(Item, :count).by(1)
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
