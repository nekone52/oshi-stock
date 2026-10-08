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
  end
end
