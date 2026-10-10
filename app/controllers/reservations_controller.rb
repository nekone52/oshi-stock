class ReservationsController < ApplicationController
  # 予約の一覧
  # before_action で推しを探していないので、ここで Current.user から始めて「自分のグッズだけ」にする
  def index
    # 予約 = 予約中 + 届いたけど未払いのもの(ホーム・推しキャラの詳細と同じ。支払うまで残して、払い忘れを防ぐ)
    # 【自分の言葉】ログインしているユーザーの、予約中と、所持中で未払いのアイテム。未払いは上へ
    @reserved_items = Current.user.items.reserved.or(Current.user.items.owned.where(paid: false)).unpaid_first
    # 上の「これから支払う金額」の箱(計算はモデルのまとめ係 user.rb。ホームと同じ数字になる)
    # 【自分の言葉】ユーザーがこれから支払う金額の合計
    @unpaid_total   = Current.user.unpaid_total
    @unpaid_count   = Current.user.unpaid_items.count   # ログイン中の人の、未払いのグッズを数える
    @due_soon_count = Current.user.due_soon_count       # ログイン中の人の、期限7日以内の数(モデルで数えてある)
  end

  def new
  end
end
