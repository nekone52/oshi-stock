require "rails_helper"

RSpec.describe Item, type: :model do
  describe "バリデーション" do
    it "名前と推しがあれば有効(個数は1、状態は「ほしい」、未払いが最初から入る)" do
      item = build(:item)
      expect(item).to be_valid
      expect(item.quantity).to eq(1)
      expect(item).to be_wanted
      expect(item.paid).to be(false)
    end

    it "カテゴリは空でも有効" do
      expect(build(:item, category: nil)).to be_valid
    end

    it "推しがいなければ無効" do
      expect(build(:item, character: nil)).not_to be_valid
    end

    it "名前が空なら無効" do
      item = build(:item, name: "")
      expect(item).not_to be_valid
      expect(item.errors[:name]).to include("を入力してください")
    end

    it "名前が51文字なら無効" do
      expect(build(:item, name: "あ" * 51)).not_to be_valid
    end

    it "単価は空でも、0円でも有効" do
      expect(build(:item, price: nil)).to be_valid
      expect(build(:item, price: 0)).to be_valid
    end

    it "単価がマイナス・小数なら無効" do
      expect(build(:item, price: -1)).not_to be_valid
      expect(build(:item, price: 1.5)).not_to be_valid
    end

    it "個数が空なら「入力してください」だけを出す" do
      item = build(:item, quantity: nil)
      expect(item).not_to be_valid
      expect(item.errors.full_messages).to eq([ "個数を入力してください" ])
    end

    it "個数が0なら無効" do
      item = build(:item, quantity: 0)
      expect(item).not_to be_valid
      expect(item.errors[:quantity]).to include("は1以上の値にしてください")
    end

    it "目標個数は空でも、1以上の整数でも有効" do
      expect(build(:item, target_quantity: nil)).to be_valid
      expect(build(:item, target_quantity: 3)).to be_valid
    end

    it "目標個数が0なら無効" do
      item = build(:item, target_quantity: 0)
      expect(item).not_to be_valid
      expect(item.errors[:target_quantity]).to include("は1以上の値にしてください")
    end

    it "目標個数が小数なら無効" do
      expect(build(:item, target_quantity: 1.5)).not_to be_valid
    end

    it "単価は100万円まで、個数・目標個数は999個まで" do
      expect(build(:item, price: 1_000_000, quantity: 999, target_quantity: 999)).to be_valid
      expect(build(:item, price: 1_000_001)).not_to be_valid
      expect(build(:item, quantity: 1000)).not_to be_valid
      expect(build(:item, target_quantity: 1000)).not_to be_valid
    end

    it "URL は空でも、http・https の URL でも有効" do
      expect(build(:item, url: "")).to be_valid
      expect(build(:item, url: "https://example.com/goods?id=1")).to be_valid
    end

    it "URL の前後に余計な文字があれば無効" do
      expect(build(:item, url: "メモ https://example.com")).not_to be_valid
      expect(build(:item, url: "javascript:alert(1)")).not_to be_valid
    end

    it "決まっていない状態(status)なら無効" do
      item = build(:item, status: "hack")
      expect(item).not_to be_valid
      expect(item.errors[:status]).to be_present
    end

    describe "商品画像" do
      it "PNG の画像なら有効" do
        item = build(:item)
        item.image.attach(io: file_fixture("icon.png").open, filename: "icon.png", content_type: "image/png")
        expect(item).to be_valid
      end

      it "GIF の画像なら無効" do
        item = build(:item)
        item.image.attach(io: file_fixture("icon.gif").open, filename: "icon.gif", content_type: "image/gif")
        expect(item).not_to be_valid
        expect(item.errors[:image]).to include("は JPEG, PNG, WebP 形式にしてください")
      end
    end
  end

  describe "関連" do
    it "推しを消すと、その推しのグッズも消える" do
      character = create(:character)
      create_list(:item, 2, character: character)
      expect { character.destroy }.to change(Item, :count).by(-2)
    end
  end

  describe "#secured_quantity(確保した数)" do
    it "ほしい物は、まだ確保していないので0" do
      expect(build(:item, status: :wanted, quantity: 2).secured_quantity).to eq(0)
    end

    it "予約中・所持は、個数がそのまま確保した数" do
      expect(build(:item, status: :reserved, quantity: 2).secured_quantity).to eq(2)
      expect(build(:item, status: :owned, quantity: 3).secured_quantity).to eq(3)
    end
  end

  describe ".unpaid_first(並べ方)" do
    it "未払いを先に、支払い期限の近い順に並べる(期限が未定のものは、未払いの中で最後)" do
      character = create(:character)
      paid = create(:item, character: character, paid: true, payment_deadline: Date.current + 1)
      no_deadline = create(:item, character: character, paid: false, payment_deadline: nil)
      later = create(:item, character: character, paid: false, payment_deadline: Date.current + 20)
      soon = create(:item, character: character, paid: false, payment_deadline: Date.current + 3)

      expect(Item.unpaid_first).to eq([ soon, later, no_deadline, paid ])
    end
  end
end
