RSpec.shared_context "ホームの推しとグッズ" do
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
end
