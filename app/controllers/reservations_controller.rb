class ReservationsController < ApplicationController
  # 予約の一覧
  # before_action で推しを探していないので、ここで Current.user から始めて「自分のグッズだけ」にする
  def index
    # 予約 = 予約中 + 届いたけど未払いのもの(ホーム・推しキャラの詳細と同じ。支払うまで残して、払い忘れを防ぐ)
    # 【自分の言葉】ログインしているユーザーの、予約中と、所持中で未払いのアイテム。未払いは上へ
    # includes:カードに出す推しと画像も、まとめて取り出す(グッズの数だけデータベースに聞きに行かないようにする。ホームと同じ)
    @reserved_items = Current.user.items.reserved.or(Current.user.items.owned.where(paid: false))
                                  .includes(:character, image_attachment: :blob).unpaid_first
    # 上の「これから支払う金額」の箱(計算はモデルのまとめ係 user.rb。ホームと同じ数字になる)
    # 【自分の言葉】ユーザーがこれから支払う金額の合計
    @unpaid_total   = Current.user.unpaid_total
    @unpaid_count   = Current.user.unpaid_items.count   # ログイン中の人の、未払いのグッズを数える
    @due_soon_count = Current.user.due_soon_count       # ログイン中の人の、期限7日以内の数(モデルで数えてある)
    # 発売月ごとの箱に仕分ける(予約画面でしか使わない並べ方なので、モデルではなくここで)
    # 【自分の言葉】予約している一覧から、発売月ごとにグループ化する
    items_by_month = @reserved_items.group_by(&:release_month)
    # 発売月が空(nil)の箱は「発売日待ち」として、べつのお皿によける(日付とくらべられないので、並べる前に)
    @waiting_items  = items_by_month.delete(nil) || []
    # のこりの箱を、発売月の古い順(10月 → 11月 → …)に並べる
    @items_by_month = items_by_month.sort_by { |release_month, _items| release_month }
    # 月ごとの金額(見出しの横の「¥8,800」)。その月のグッズ全部の 単価 × 個数 を足す(支払済も入れる。単価が空なら0円)
    # 予約画面でしか使わないので、仕分けと同じくここで
    @month_totals = @items_by_month.to_h.transform_values { |items| items.sum { |item| item.price.to_i * item.quantity } }
  end
end
