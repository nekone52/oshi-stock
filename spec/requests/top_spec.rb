require "rails_helper"

RSpec.describe "ホーム画面", type: :request do
  let(:user) { create(:user) }

  describe "GET /" do
    it "ログインしていないと、ログイン画面へ移る" do
      get root_path
      expect(response).to redirect_to(new_session_path)
    end

    it "推しがいないときは、「まだ推しがいません」を出す" do
      sign_in_as(user)
      get root_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("まだ推しがいません")
    end

    context "推しとグッズがあるとき" do
      let!(:hinata) { create(:character, user: user, name: "ヒナタ") }
      let!(:aoi) { create(:character, user: user, name: "アオイ") }

      before do
        create(:item, character: hinata, name: "ヒナタの缶バッジ", status: :wanted)
        create(:item, character: hinata, name: "ヒナタのアクスタ", status: :reserved, price: 1650, quantity: 2,
                      payment_deadline: Date.current + 3)
        create(:item, character: aoi, name: "アオイのぬい", status: :reserved, price: 3000, paid: true)
        create(:item, character: aoi, name: "アオイのタオル", status: :owned, price: 1000)
        create(:item, character: create(:character, user: create(:user)), name: "ほかの人のグッズ", status: :owned)
        sign_in_as(user)
      end

      it "自分のグッズを、ほしい物・予約注文中・所持の3つに分けて出す(ほかの人のグッズは出さない)" do
        get root_path
        body = response.body

        expect(body).to include("ヒナタの缶バッジ", "ヒナタのアクスタ", "アオイのぬい", "アオイのタオル")
        expect(body).not_to include("ほかの人のグッズ")
      end

      it "これから支払う金額は、支払っていない予約中・所持のグッズの合計(単価 × 個数)" do
        get root_path
        # ヒナタのアクスタ 1650 × 2 + アオイのタオル 1000 = 4300(アオイのぬいは支払い済み、缶バッジはほしい物なので数えない)
        expect(response.body).to include("¥4,300", "未払い 2件", "期限7日以内 1件")
      end

      it "推しのアイコンを押すと、その推しのグッズだけを出す" do
        get root_path(character_id: aoi.id)
        body = response.body

        expect(body).to include("アオイのぬい", "アオイのタオル")
        expect(body).not_to include("ヒナタの缶バッジ")
        expect(body).not_to include("ヒナタのアクスタ")
      end

      it "ほかの人の推しの番号を入れても、ほかの人のグッズは出ない" do
        someone_character = Character.where.not(user: user).first
        get root_path(character_id: someone_character.id)

        expect(response).to have_http_status(:ok)
        expect(response.body).not_to include("ほかの人のグッズ")
      end

      it "グッズ名で検索すると、その言葉をふくむグッズだけを出す" do
        get root_path(q: "アクスタ")
        body = response.body

        expect(body).to include("ヒナタのアクスタ", "「アクスタ」の検索結果")
        expect(body).not_to include("ヒナタの缶バッジ")
      end

      it "検索の言葉に % があっても、全部のグッズが当たってしまわない" do
        get root_path(q: "%")
        expect(response.body).not_to include("ヒナタのアクスタ")
      end
    end
  end
end
