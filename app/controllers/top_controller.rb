class TopController < ApplicationController
  # ホーム画面(推しの絞り込み・検索・ほしい物 / 予約注文中 / 所持の3つのセクション)
  def index
    # 推しの絞り込みのアイコン用(ログイン中ユーザーの推しだけ)
    @characters = Current.user.characters.with_attached_icon.order(:created_at)
    # 推しがまだいないときは、「まだ推しがいません」の画面を出す
    return render :start if @characters.empty?

    # ① 自分のグッズを全部取ってくる(推しキャラを通して持っているグッズ)
    @items = Current.user.items.includes(:character, image_attachment: :blob).order(created_at: :desc)
    # ② 推しのアイコンが押されていたら、その推しのグッズだけにしぼる
    #    自分のグッズの中からしぼるので、ほかの人の推しの番号を入れても何も出てこない
    @selected_character = @characters.find_by(id: params[:character_id]) if params[:character_id].present?
    @items = @items.where(character: @selected_character) if @selected_character
    # 検索欄にグッズ名が入っていたら、名前にその言葉をふくむグッズだけにしぼる(大文字・小文字は区別しない)
    @query = params[:q].to_s.strip
    @items = @items.where("items.name ILIKE ?", "%#{Item.sanitize_sql_like(@query)}%") if @query.present?

    # ③ ステータスごとに3つに分ける(enum のおかげで、名前で書ける)
    @wanted_items   = @items.wanted      # ほしい物
    # 予約中 + 届いたけど未払いのもの(README:支払うまで予約注文中にも残して、払い忘れを防ぐ)
    # 未払いを先に、支払い期限の近い順に並べる(Item の scope。期限切れを見落とさないように)
    @reserved_items = @items.reserved.or(@items.owned.where(paid: false)).unpaid_first
    @owned_items    = @items.owned       # 所持

    # これから支払う金額のまとめ(支払っていない、予約中・所持のグッズ。絞り込み・検索に関係なく全部の推しで数える)
    unpaid_items = Current.user.items.where(paid: false).where.not(status: :wanted)
    @unpaid_total = unpaid_items.sum("COALESCE(items.price, 0) * items.quantity")
    @unpaid_count = unpaid_items.count
    @due_soon_count = unpaid_items.where(payment_deadline: Date.current..7.days.from_now.to_date).count
  end

  # 「まだ推しがいません」の画面(推しがいないときは、ホームからもこの画面を出す)
  def start
  end
end
