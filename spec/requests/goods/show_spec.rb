require "rails_helper"

# グッズの詳細(グッズのカード)
RSpec.describe "グッズの詳細", type: :request do
  let(:user) { create(:user) }

  describe "GET /goods/:id(グッズの詳細)" do
    let(:character) { create(:character, user: user, name: "ヒナタ") }
    let(:item) do
      create(:item, character: character, name: "夏祭りアクスタ", shop_name: "公式ショップ", price: 1650, quantity: 2,
                    category: user.categories.find_by!(name: "アクスタ"), status: :owned, paid: false,
                    release_month: Date.new(2026, 10, 1), release_period: "上旬", memo: "特典付き",
                    url: "https://example.com/goods/1")
    end

    it "ログインしていないと、ログイン画面へ移る" do
      get good_path(item)
      expect(response).to redirect_to(new_session_path)
    end

    it "自分のグッズなら、買ったときの記録が見られる" do
      sign_in_as(user)
      get good_path(item)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("夏祭りアクスタ", "ヒナタ", "アクスタ", "公式ショップ", "¥1,650 × 2個", "¥3,300",
                                       "2026年10月 上旬", "未払い", "特典付き", "所持")
      expect(response.body).to include(edit_good_path(item))
      # 商品ページは、新しいタブで安全に開く
      expect(response.body).to include('href="https://example.com/goods/1"', 'rel="noopener noreferrer"')
    end

    it "商品ページのリンクには、お店の住所(www. を取ったもの)が出る" do
      item.update!(url: "https://www.animate-onlineshop.jp/pn/goods/pd/3012345/")
      sign_in_as(user)
      get good_path(item)

      expect(response.body).to include("animate-onlineshop.jp ↗")
      expect(response.body).not_to include("www.animate-onlineshop.jp ↗")
    end

    it "http・https 以外の URL は、リンクにしない(javascript: などを開かせない)" do
      item.update_column(:url, "javascript:alert(1)") # チェックを通らない値を、むりやり入れた場合
      sign_in_as(user)
      get good_path(item)

      expect(response.body).not_to include("javascript:alert(1)")
      expect(response.body).not_to include("商品ページ")
    end

    it "ほかのユーザーのグッズは、見つからない(404)" do
      other_item = create(:item, character: create(:character, user: create(:user)))

      sign_in_as(user)
      get good_path(other_item)
      expect(response).to have_http_status(:not_found)
    end

    # 「<」の戻り先は、グッズの状態で決める(くわしい分け方は spec/helpers/items_helper_spec.rb)
    it "「<」で、予約中のグッズは予約画面へ戻る" do
      reserved_item = create(:item, character: character, status: :reserved)

      sign_in_as(user)
      get good_path(reserved_item)
      expect(response.body).to include(%(<a aria-label="戻る" class="flex h-11 w-11 items-center justify-center text-ink" href="#{reservations_path}"))
    end

    it "「<」で、ほしい物はグッズ一覧(ほしい物)へ戻る" do
      wanted_item = create(:item, character: character, status: :wanted)

      sign_in_as(user)
      get good_path(wanted_item)
      expect(response.body).to include(%(<a aria-label="戻る" class="flex h-11 w-11 items-center justify-center text-ink" href="#{goods_path(status: 'wanted')}"))
    end
  end
end
