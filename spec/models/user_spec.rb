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
      user = build(:user, email_address: "#{'a' * 244}@example.com") # 244 + 12 = 256文字
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
  end
end
