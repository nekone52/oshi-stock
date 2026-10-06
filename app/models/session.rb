class Session < ApplicationRecord
  # 【入場パスの持ち主】
  # このセッション（入場パス）がどのユーザーのものかを結びつける
  # これがないと「誰がログインしているか」が分からずログインできない
  belongs_to :user
end
