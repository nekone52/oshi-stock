class Current < ActiveSupport::CurrentAttributes
  # 【入場パスのポケット】
  # 今アクセスしている人の通行手形（Session）を一時的に入れておく場所
  attribute :session

  # 【持ち主の照会窓口】
  # 「Current.user」と聞かれたら、ポケットの中のパス（session）に「持ち主だれ？」と丸投げする
  # まだログイン前でパスが空っぽ（nil）でも、怒らず安全に「誰もいないよ（nil）」と答える
  delegate :user, to: :session, allow_nil: true
end
