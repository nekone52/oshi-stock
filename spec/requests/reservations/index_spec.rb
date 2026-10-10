require "rails_helper"

# 予約の一覧
RSpec.describe "予約の一覧", type: :request do
  let(:user) { create(:user) }

  describe "GET /reservations" do
    it "ログインしていないと、ログイン画面へ移る" do
      get reservations_path
      expect(response).to redirect_to(new_session_path)
    end

    it "ログインしていれば、予約の画面が開ける" do
      sign_in_as(user)
      get reservations_path
      expect(response).to have_http_status(:ok)
    end

    it "上の箱に、これから支払う金額と件数が出る(ホームと同じ数字)" do
      character = create(:character, user: user)
      create(:item, character: character, status: :reserved, price: 3300, payment_deadline: Date.current + 2)
      create(:item, character: character, status: :reserved, price: 1000, paid: true)
      create(:item, character: character, status: :owned, price: 1000, quantity: 2)

      sign_in_as(user)
      get reservations_path
      expect(response.body).to include("¥5,300", "予約 3件", "未払い 2件", "期限7日以内 1件")
    end

    it "発売月ごとに、古い月から順に見出しが出る(未払いが先頭でも、月の順はくずれない)" do
      character = create(:character, user: user)
      create(:item, character: character, status: :reserved, name: "11月のぬい", release_month: Date.new(2026, 11, 1))
      create(:item, character: character, status: :reserved, name: "10月の缶バッジ", release_month: Date.new(2026, 10, 1), paid: true)

      sign_in_as(user)
      get reservations_path
      body = response.body
      expect(body).to include("10月発売", "11月発売")
      # 10月の見出し → 10月のグッズ → 11月の見出し → 11月のグッズ の順に並ぶ
      expect(body.index("10月発売")).to be < body.index("10月の缶バッジ")
      expect(body.index("10月の缶バッジ")).to be < body.index("11月発売")
      expect(body.index("11月発売")).to be < body.index("11月のぬい")
    end

    it "発売月が空のグッズは、月の見出しではなく、いちばん下の「発売日待ち」の箱に入る" do
      character = create(:character, user: user)
      create(:item, character: character, status: :reserved, name: "10月の缶バッジ", release_month: Date.new(2026, 10, 1))
      create(:item, character: character, status: :reserved, name: "新作アクスタ", release_month: nil)

      sign_in_as(user)
      get reservations_path
      body = response.body
      expect(body).to include("発売日待ち")
      # 発売日待ちの箱(id="waiting")は月の見出しより下にあって、その中に新作アクスタがいる
      expect(body.index("10月の缶バッジ")).to be < body.index('id="waiting"')
      expect(body.index('id="waiting"')).to be < body.index("新作アクスタ")
    end

    it "カードに、推し・お店・金額(単価×個数)・状態のバッジが出る" do
      character = create(:character, user: user, name: "ねこ太")
      create(:item, character: character, status: :reserved, name: "ねこ太のぬい", shop_name: "アニメイト",
                    price: 1500, quantity: 2, release_month: Date.new(2026, 10, 1))
      create(:item, character: character, status: :owned, name: "届いたアクスタ", release_month: Date.new(2026, 10, 1))

      sign_in_as(user)
      get reservations_path
      expect(response.body).to include("ねこ太 · アニメイト", "¥3,000", "(×2)", "未払い", "届いた・未払い")
    end

    it "「支払った」「届いた」ボタンが、ホームと同じ道につながっている(届いたものには「届いた」を出さない)" do
      character = create(:character, user: user)
      reserved = create(:item, character: character, status: :reserved)
      arrived  = create(:item, character: character, status: :owned)

      sign_in_as(user)
      get reservations_path
      body = response.body
      expect(body).to include(toggle_paid_good_path(reserved), receive_good_path(reserved), toggle_paid_good_path(arrived))
      expect(body).not_to include(receive_good_path(arrived))
    end

    it "予約画面で「届いた」を押すと、所持に移って予約画面に戻る" do
      character = create(:character, user: user)
      item = create(:item, character: character, status: :reserved)

      sign_in_as(user)
      patch receive_good_path(item), headers: { "HTTP_REFERER" => reservations_url }
      expect(response).to redirect_to(reservations_url)
      expect(item.reload).to be_owned
    end

    it "「＋ 予約を登録」は、グッズ登録を「予約中」で開く" do
      sign_in_as(user)
      get reservations_path
      expect(response.body).to include(new_good_path(status: "reserved"))
    end

    it "カードを押すと、そのグッズの詳細へ行ける(そこから編集できる)" do
      item = create(:item, character: create(:character, user: user), status: :reserved)

      sign_in_as(user)
      get reservations_path
      expect(response.body).to include(%(href="#{good_path(item)}"))
    end

    it "月の見出しに、その月の件数と金額(単価×個数。支払済も入れる)が出る" do
      character = create(:character, user: user)
      october = Date.new(2026, 10, 1)
      create(:item, character: character, status: :reserved, price: 5500, quantity: 1, release_month: october)
      create(:item, character: character, status: :reserved, price: 1650, quantity: 2, release_month: october, paid: true)
      create(:item, character: character, status: :reserved, price: nil, release_month: october)
      create(:item, character: character, status: :reserved, price: 1000, release_month: Date.new(2026, 11, 1))

      sign_in_as(user)
      get reservations_path
      expect(response.body).to include("3件 · ¥8,800", "1件 · ¥1,000")
    end

    it "発売日待ちのグッズがないときは、お知らせも箱も出さない" do
      character = create(:character, user: user)
      create(:item, character: character, status: :reserved, release_month: Date.new(2026, 10, 1))

      sign_in_as(user)
      get reservations_path
      expect(response.body).not_to include("発売日待ち")
    end

    # ホームで選んだ推しを引きつぐ(?character_id=番号)
    context "推しの番号がついているとき" do
      let(:hinata) { create(:character, user: user, name: "ヒナタ") }
      let(:aoi) { create(:character, user: user, name: "アオイ") }

      before do
        create(:item, character: hinata, status: :reserved, name: "ヒナタの缶バッジ", price: 1000)
        create(:item, character: aoi, status: :reserved, name: "アオイのぬい", price: 2000)
        sign_in_as(user)
      end

      it "その推しの予約だけが出て、上の箱は全員分のまま" do
        get reservations_path(character_id: hinata.id)
        body = response.body

        expect(body).to include("ヒナタの缶バッジ")
        expect(body).not_to include("アオイのぬい")
        expect(body).to include("¥3,000", "予約 2件")
      end

      it "「〇〇 で絞りこみ中」と件数と、全員分にもどる「やめる」が出る" do
        get reservations_path(character_id: hinata.id)
        body = response.body

        expect(body).to include(%(<span class="font-bold">ヒナタ</span> で絞りこみ中), "予約 1件", "絞り込みをやめる")
        expect(body).to include(%(href="#{reservations_path}"))
      end

      it "推しを選んでいないときは、絞りこみ中の帯を出さない" do
        get reservations_path
        expect(response.body).not_to include("絞りこみ中", "絞り込みをやめる")
      end

      it "ほかの人の推しの番号だと、しぼらずに全員分を出す" do
        other_character = create(:character, user: create(:user))
        get reservations_path(character_id: other_character.id)

        expect(response.body).to include("ヒナタの缶バッジ", "アオイのぬい")
      end
    end

    # 推しの色の枠(#85)。期限が近いことは、枠の色のかわりに札で知らせる
    describe "推しの色の枠と「⚠ 期限が近い」の札" do
      let(:character) { create(:character, user: user) }

      before { sign_in_as(user) }

      it "カードの枠が推しの色になる" do
        create(:item, character: character, status: :reserved)
        get reservations_path
        expect(response.body).to include("border: 2px solid #{character.display_color}")
      end

      it "未払いで、支払い期限が7日以内なら、札が出る" do
        create(:item, character: character, status: :reserved, paid: false, payment_deadline: Date.current + 3)
        get reservations_path
        expect(response.body).to include("⚠ 期限が近い")
      end

      it "期限がまだ先のときや、支払い済みのときは、札を出さない" do
        create(:item, character: character, status: :reserved, paid: false, payment_deadline: Date.current + 20)
        create(:item, character: character, status: :reserved, paid: true, payment_deadline: Date.current + 3)
        get reservations_path
        expect(response.body).not_to include("⚠ 期限が近い")
      end
    end
  end
end
