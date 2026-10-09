require "rails_helper"

RSpec.describe Character, type: :model do
  describe "バリデーション" do
    it "名前とユーザーがあれば有効" do
      expect(build(:character)).to be_valid
    end

    it "名前が空なら無効" do
      character = build(:character, name: "")
      expect(character).not_to be_valid
      expect(character.errors[:name]).to include("を入力してください")
    end

    it "名前が50文字なら有効" do
      expect(build(:character, name: "あ" * 50)).to be_valid
    end

    it "名前が51文字なら無効" do
      character = build(:character, name: "あ" * 51)
      expect(character).not_to be_valid
      expect(character.errors[:name]).to include("は50文字以内で入力してください")
    end

    it "ユーザーがいなければ無効" do
      expect(build(:character, user: nil)).not_to be_valid
    end

    it "色は空でも有効" do
      expect(build(:character, color: "")).to be_valid
    end

    it "色が「#」+ 16進数6桁でなければ無効(画面の style に入るため)" do
      character = build(:character, color: "red; background: url(x)")
      expect(character).not_to be_valid
      expect(character.errors[:color]).to include("は不正な値です")
    end

    it "明るすぎる色(まっ黄色)は、保存する前に落ち着いた色に直る" do
      expect(build(:character, color: "#FFFF00").color).to eq("#B8B521")
    end

    describe "アイコン画像" do
      it "PNG の画像なら有効" do
        character = build(:character)
        character.icon.attach(io: file_fixture("icon.png").open, filename: "icon.png", content_type: "image/png")
        expect(character).to be_valid
      end

      it "GIF の画像なら無効" do
        character = build(:character)
        character.icon.attach(io: file_fixture("icon.gif").open, filename: "icon.gif", content_type: "image/gif")
        expect(character).not_to be_valid
        expect(character.errors[:icon]).to include("は JPEG, PNG, WebP 形式にしてください")
      end

      it "5MB 以上なら無効" do
        character = build(:character)
        big_png = StringIO.new(file_fixture("icon.png").binread + ("0" * 5.megabytes))
        character.icon.attach(io: big_png, filename: "big.png", content_type: "image/png")
        expect(character).not_to be_valid
        expect(character.errors[:icon]).to include("は 5MB 以下にしてください")
      end
    end
  end

  describe "#display_color" do
    it "色があれば、その色を返す" do
      expect(build(:character, color: "#2F5DAA").display_color).to eq("#2F5DAA")
    end

    it "色が空なら、アプリのピンクを返す" do
      expect(build(:character, color: "").display_color).to eq(Character::DEFAULT_COLOR)
    end
  end

  describe "#item_counts と #owned_total" do
    let(:character) { create(:character) }

    it "グッズがないときは、数は空で、合計は 0" do
      expect(character.item_counts).to eq({})
      expect(character.owned_total).to eq(0)
    end

    it "状態ごとに数え、所持のグッズだけ 単価 × 個数 をたす" do
      create(:item, character: character, status: :wanted, price: 550)
      create(:item, character: character, status: :reserved, price: 1650)
      create(:item, character: character, status: :owned, price: 550, quantity: 3)
      create(:item, character: character, status: :owned, price: 5500)
      create(:item, character: character, status: :owned, price: nil)
      # ほかの推しのグッズは数えない
      create(:item, status: :owned, price: 9999)

      expect(character.item_counts).to eq({ "wanted" => 1, "reserved" => 1, "owned" => 3 })
      expect(character.owned_total).to eq(7150)
    end
  end
end
