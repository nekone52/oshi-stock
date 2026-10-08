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

      it "グッズのカードを押すと、そのグッズの詳細へ行ける" do
        get root_path
        Item.joins(:character).where(characters: { user_id: user.id }).find_each do |item|
          expect(response.body).to include(good_path(item))
        end
      end

      it "予約注文中に「支払った」「届いた」のボタンがある" do
        reserved_item = Item.find_by!(name: "ヒナタのアクスタ")
        get root_path

        expect(response.body).to include(toggle_paid_good_path(reserved_item), receive_good_path(reserved_item))
      end

      it "届いたけど未払いのものは、予約注文中にも「届いた・未払い」として残す" do
        get root_path
        # アオイのタオルは所持・未払い
        expect(response.body).to include("届いた・未払い")
        expect(response.body.scan("アオイのタオル").size).to be >= 2
      end

      it "予約注文中は、未払いを先に、支払い期限の近い順に並べる" do
        create(:item, character: hinata, name: "期限が近い未払い", status: :reserved, paid: false, payment_deadline: Date.current + 1)
        get root_path
        section = response.body[/予約注文中.*?所持グッズ/m]

        # 期限が近い未払い → ヒナタのアクスタ(未払い・3日後)→ アオイのタオル(届いた・未払い・期限なし)→ アオイのぬい(支払い済み)
        expect(section.index("期限が近い未払い")).to be < section.index("ヒナタのアクスタ")
        expect(section.index("ヒナタのアクスタ")).to be < section.index("アオイのタオル")
        expect(section.index("アオイのタオル")).to be < section.index("アオイのぬい")
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
