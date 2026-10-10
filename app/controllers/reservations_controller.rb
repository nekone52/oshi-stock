class ReservationsController < ApplicationController
  # 予約の一覧
  # before_action で推しを探していないので、ここで Current.user から始めて「自分のグッズだけ」にする
  def index
    # 予約 = 予約中 + 届いたけど未払いのもの(ホーム・推しキャラの詳細と同じ。支払うまで残して、払い忘れを防ぐ)
    # 【自分の言葉】ログインしているユーザーの、予約中と、所持中で未払いのアイテム。未払いは上へ
    @reserved_items = Current.user.items.reserved.or(Current.user.items.owned.where(paid: false)).unpaid_first
  end

  def new
  end
end
