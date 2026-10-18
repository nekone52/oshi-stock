require "rails_helper"

RSpec.describe User, type: :model do
  describe "バリデーション" do
    it "メールアドレスとパスワードがあれば有効" do
      expect(build(:user)).to be_valid
    end

    it "メールアドレスが空なら無効" do
      user = build(:user, email_address: "")
      expect(user).not_to be_valid
      expect(user.errors[:email_address]).to include("を入力してください")
    end

    it "メールアドレスの形でなければ無効" do
      user = build(:user, email_address: "not-an-email")
      expect(user).not_to be_valid
      expect(user.errors[:email_address]).to include("は不正な値です")
    end

    it "メールアドレスが256文字以上の場合は無効であること" do
      user = build(:user, email_address: "#{'a' * 244}@example.com")
      expect(user).to be_invalid
    end

    it "同じメールアドレスは登録できない(大文字・小文字がちがっても同じとみなす)" do
      create(:user, email_address: "oshi@example.com")
      user = build(:user, email_address: "OSHI@example.com")
      expect(user).not_to be_valid
      expect(user.errors[:email_address]).to include("はすでに存在します")
    end

    it "パスワードが空なら無効" do
      user = build(:user, password: "", password_confirmation: "")
      expect(user).not_to be_valid
      expect(user.errors[:password]).to include("を入力してください")
    end

    it "パスワードが8文字未満なら無効" do
      user = build(:user, password: "short", password_confirmation: "short")
      expect(user).not_to be_valid
      expect(user.errors[:password]).to include("は8文字以上で入力してください")
    end

    it "確認用のパスワードが一致しなければ無効" do
      user = build(:user, password: "password", password_confirmation: "different")
      expect(user).not_to be_valid
      expect(user.errors[:password_confirmation]).to be_present
    end
  end

  describe "メールアドレスのお掃除(normalizes)" do
    it "前後の空白を消して、小文字にそろえる" do
      user = create(:user, email_address: "  Oshi@Example.COM ")
      expect(user.email_address).to eq("oshi@example.com")
    end
  end

  describe "パスワードの暗号化(has_secure_password)" do
    it "パスワードそのものではなく、暗号化した値を保存する" do
      user = create(:user, password: "password", password_confirmation: "password")
      expect(user.password_digest).not_to eq("password")
      expect(user.authenticate("password")).to eq(user)
      expect(user.authenticate("wrong-password")).to be(false)
    end
  end

  describe "関連" do
    it "ユーザーを消すと、ログインの記録(sessions)も消える" do
      user = create(:user)
      user.sessions.create!
      expect { user.destroy }.to change(Session, :count).by(-1)
    end

    it "ユーザーを消すと、そのユーザーの推しキャラも消える" do
      user = create(:user)
      create_list(:character, 2, user: user)
      expect { user.destroy }.to change(Character, :count).by(-2)
    end

    it "推しキャラを通して、自分のグッズだけをまとめて取り出せる(has_many through)" do
      user = create(:user)
      my_item = create(:item, character: create(:character, user: user))
      create(:item, character: create(:character, user: create(:user)))
      expect(user.items).to contain_exactly(my_item)
    end

    it "ユーザーを消すと、そのユーザーのカテゴリも消える" do
      user = create(:user)
      expect { user.destroy }.to change(Category, :count).by(-5)
    end
  end

  describe "テーマの色(theme_color)" do
    it "何も選ばなければ、最初のピンク(#E8577A)が入る" do
      expect(User.new.theme_color).to eq("#E8577A")
    end

    it "「#」+ 16進数6けた なら有効(小文字でもよい)" do
      expect(build(:user, theme_color: "#4e6fa3")).to be_valid
    end

    it "空なら無効" do
      user = build(:user, theme_color: "")
      expect(user).not_to be_valid
      expect(user.errors[:theme_color]).to include("を入力してください")
    end

    it "色の形でなければ無効(画面の style に入るので、ほかの文字を入れさせない)" do
      [ "red", "#12345", "#1234567", "#GGGGGG", "#E8577A; color: red" ].each do |value|
        expect(build(:user, theme_color: value)).not_to be_valid, "#{value} が通ってしまった"
      end
    end

    it "真っ青は、目がチカチカしないように、保存する前に落ち着いた色に直る" do
      expect(build(:user, theme_color: "#0000FF").theme_color).to eq("#3333CC")
    end
  end

  describe "これから支払う金額のまとめ" do
    let(:user) { create(:user) }
    let(:character) { create(:character, user: user) }

    before do
      create(:item, character: character, status: :reserved, price: 1000, quantity: 2, payment_deadline: Date.current + 3)
      create(:item, character: character, status: :owned, price: 500, payment_deadline: Date.current + 10)
      create(:item, character: character, status: :reserved, price: nil)
      create(:item, character: character, status: :reserved, price: 3000, paid: true)
      create(:item, character: character, status: :wanted, price: 800)
      create(:item, character: create(:character), status: :reserved, price: 9999)
    end

    it "支払っていない、予約中・所持のグッズだけを選ぶ(ほしい物・支払い済み・ほかの人のグッズは入らない)" do
      expect(user.unpaid_items.count).to eq(3)
    end

    it "合計は 単価 × 個数 をたす(単価が空のグッズは 0円)" do
      expect(user.unpaid_total).to eq(2500)
    end

    it "支払い期限が7日以内のものだけを数える" do
      expect(user.due_soon_count).to eq(1)
    end
  end

  describe "最初のカテゴリ" do
    it "ユーザーを作ると、最初の5種類のカテゴリが自動でできる" do
      user = create(:user)
      expect(user.categories.pluck(:name)).to contain_exactly("アクスタ", "缶バッジ", "ぬいぐるみ", "ブロマイド", "その他")
    end
  end
end
