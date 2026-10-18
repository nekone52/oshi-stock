# システムテスト(spec/system)の準備。#28
# rack_test = 画面の設計図(HTML)を読んで、押したり入力したりしたことにする道具。本物のブラウザを開かないので速い
# JavaScript は動かないので、カレンダー・切り抜き・消去の確認などは、MVP のあとで本物の Chrome(B 案)にする
RSpec.configure do |config|
  config.before(:each, type: :system) do
    driven_by :rack_test
  end
end
