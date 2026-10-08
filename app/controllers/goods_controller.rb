class GoodsController < ApplicationController
  # 1つのグッズに対するアクションは、最初に「自分のグッズの中から」探しておく(ほかの人のグッズは見つからず 404)
  before_action :set_item, only: [ :show, :edit, :update, :destroy, :receive, :toggle_paid ]

  # グッズの一覧(まだモック)
  def index
  end

  # グッズの詳細(グッズのカード。購入先・金額・発売・支払いなど、買ったときの記録を見る)
  def show
  end

  # グッズを登録の画面を開く(入力フォーム用)
  def new
    # フォームを組み立てるための、空のグッズ(個数は1、状態は「ほしい」が最初から入る)
    @item = Item.new
    set_form_choices
  end

  # 「登録する」ボタンを押したときの保存処理
  def create
    @item = Item.new(item_params)
    assign_character_and_category

    # 自分のグッズに同じ名前のものがあって、かつ、まだ「それでも登録する」を押していなかったら
    # 保存せずに、警告と一緒に登録画面をもう一度出す(ダブり買いを防ぐ。布教用・保存用なら、そのまま登録できる)
    # 同じ名前のグッズ(警告の中に、推しと状態を出す)
    @duplicate_items = Current.user.items.includes(:character).where(name: @item.name)
    if @duplicate_items.exists? && params[:confirm_duplicate].blank?
      set_form_choices
      render :new, status: :unprocessable_content
      return
    end

    if @item.save
      # 保存に成功:登録したグッズの詳細へ移動し、完了メッセージを表示
      redirect_to good_path(@item), notice: "グッズを登録しました"
    else
      # 保存に失敗(名前が空・推しを選んでいないなど):入力画面を再表示し、エラーメッセージを画面に残す
      set_form_choices
      render :new, status: :unprocessable_content
    end
  end

  # グッズを編集の画面を開く
  def edit
    set_form_choices
  end

  # 「保存する」ボタンを押したときの更新処理
  def update
    # 送られてきた中身を入れる(まだ保存しない。推しとカテゴリをつなげてから保存するため)
    @item.assign_attributes(item_params)
    assign_character_and_category

    # 保存して、成功・失敗で分ける
    if @item.save
      # 更新に成功:そのグッズの詳細へ戻り、完了メッセージを表示
      redirect_to good_path(@item), notice: "グッズを更新しました"
    else
      # 更新に失敗(名前が空など):編集画面を再表示し、エラーメッセージを画面に残す
      set_form_choices
      render :edit, status: :unprocessable_content
    end
  end

  # 編集画面の「このグッズを消去する」を押したときの消去処理(確認はアプリの確認ダイアログ。confirm_dialog.js)
  def destroy
    @item.destroy
    # 消去のあとは、ホームへ移動し、完了メッセージを表示
    # status: :see_other(303)は「次は GET で見に行ってね」の合図(DELETE のまま一覧へ行かないように)
    redirect_to root_path, status: :see_other, notice: "グッズを消去しました"
  end

  # ホームの「届いた」ボタン:所持に変える(支払い済みかどうかは、そのまま残す)
  def receive
    # enum のおかげで、「所持に変えて保存」が1行で書ける
    @item.owned!
    # 押した画面(ホーム)に戻る。推しで絞り込んでいても、そのまま戻れる
    redirect_back_or_to root_path, notice: "「#{@item.name}」を所持グッズに移しました"
  end

  # ホームの「支払った」ボタン:押すたびに、支払い済み ⇔ 未払い を切り替える
  def toggle_paid
    # toggle!(:paid):Rails が用意している「true ⇔ false を反対にして保存する」メソッド
    # (前は @item.update(paid: !@item.paid) と書いていた。中身は同じ)
    @item.toggle!(:paid)
    redirect_back_or_to root_path, notice: (@item.paid ? "支払い済みにしました" : "未払いに戻しました")
  end

  private

  # URL の番号のグッズを、ログイン中ユーザーのグッズの中から探す(推しキャラを通して持っているグッズ)
  def set_item
    @item = Current.user.items.find(params[:id])
  end

  # 推しとカテゴリは、フォームから送られた番号をそのまま使わない
  # ログイン中ユーザーの推し・カテゴリの中から探してつなげる(ほかの人の番号なら見つからず nil になる)
  # find ではなく find_by:見つからないときに 404 にせず、フォームにエラーを出すため
  def assign_character_and_category
    @item.character = Current.user.characters.find_by(id: params.dig(:item, :character_id))
    @item.category = Current.user.categories.find_by(id: params.dig(:item, :category_id))
  end

  # フォームの選択肢(推し・カテゴリ)を用意する。ログイン中ユーザーのものだけ
  def set_form_choices
    @characters = Current.user.characters.order(:created_at)
    @categories = Current.user.categories.order(:created_at)
  end

  # ストロングパラメーター:許可した項目だけを取り出す安全フィルター
  # character_id と category_id は入れない(上の create で、自分の推し・カテゴリから探してつなげるため)
  def item_params
    params.expect(item: [ :name, :url, :release_month, :release_period, :shop_name, :price, :quantity,
                          :status, :paid, :payment_deadline, :memo, :image ])
  end
end
