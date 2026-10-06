require "rails_helper"

RSpec.describe Category, type: :model do
  describe "バリデーション" do
    it "名前とユーザーがあれば有効" do
      expect(build(:category)).to be_valid
    end

    it "名前が空なら無効" do
      category = build(:category, name: "")
      expect(category).not_to be_valid
      expect(category.errors[:name]).to include("を入力してください")
    end

    it "名前が21文字なら無効" do
      category = build(:category, name: "あ" * 21)
      expect(category).not_to be_valid
      expect(category.errors[:name]).to include("は20文字以内で入力してください")
    end

    it "同じユーザーの中で、同じ名前は登録できない" do
      user = create(:user)
      category = build(:category, user: user, name: "アクスタ") # 「アクスタ」は最初の5種類で作られている
      expect(category).not_to be_valid
      expect(category.errors[:name]).to include("はすでに存在します")
    end

    it "ちがうユーザーなら、同じ名前でも登録できる" do
      create(:user)
      expect(build(:category, user: create(:user), name: "推しの名前入りタオル")).to be_valid
    end
  end

  describe "関連" do
    it "カテゴリを消すと、グッズは残してカテゴリだけ空にする(nullify)" do
      category = create(:category)
      item = create(:item, character: create(:character, user: category.user), category: category)

      expect { category.destroy }.not_to change(Item, :count)
      expect(item.reload.category).to be_nil
    end
  end
end
