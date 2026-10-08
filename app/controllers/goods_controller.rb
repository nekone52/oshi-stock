class GoodsController < ApplicationController
  # グッズの一覧(まだモック)
  def index
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
    # 推しとカテゴリは、フォームから送られた番号をそのまま使わない
    # ログイン中ユーザーの推し・カテゴリの中から探してつなげる(ほかの人の番号なら見つからず nil になる)
    # find ではなく find_by:見つからないときに 404 にせず、フォームにエラーを出すため
    @item.character = Current.user.characters.find_by(id: params.dig(:item, :character_id))
    @item.category = Current.user.categories.find_by(id: params.dig(:item, :category_id))

    if @item.save
      # 保存に成功:グッズ一覧へ移動し、完了メッセージを表示
      redirect_to goods_path, notice: "グッズを登録しました"
    else
      # 保存に失敗(名前が空・推しを選んでいないなど):入力画面を再表示し、エラーメッセージを画面に残す
      set_form_choices
      render :new, status: :unprocessable_content
    end
  end

  # グッズを編集の画面を開く
  def edit
    # ログイン中ユーザーのグッズの中からだけ探す(推しキャラを通して持っているグッズ。ほかの人のグッズは見つからず 404)
    @item = Current.user.items.find(params[:id])
    set_form_choices
  end

  # 「保存する」ボタンを押したときの更新処理
  def update
    # ① 自分のグッズの中から探す(edit と同じ)
    @item = Current.user.items.find(params[:id])
    # ② 送られてきた中身を入れる(まだ保存しない。推しとカテゴリをつなげてから保存するため)
    @item.assign_attributes(item_params)
    # ③ 推しとカテゴリを、ログイン中ユーザーのものの中から探してつなげる(create と同じ)
    @item.character = Current.user.characters.find_by(id: params.dig(:item, :character_id))
    @item.category = Current.user.categories.find_by(id: params.dig(:item, :category_id))

    # ④ 保存して、成功・失敗で分ける
    if @item.save
      # 更新に成功:グッズ一覧へ移動し、完了メッセージを表示
      redirect_to goods_path, notice: "グッズを更新しました"
    else
      # 更新に失敗(名前が空など):編集画面を再表示し、エラーメッセージを画面に残す
      set_form_choices
      render :edit, status: :unprocessable_content
    end
  end

  # 編集画面の「このグッズを削除する」を押したときの削除処理(確認はアプリの確認ダイアログ。confirm_dialog.js)
  def destroy
    # 自分のグッズの中からだけ探す(ほかの人のグッズは見つからず 404)
    @item = Current.user.items.find(params[:id])
    @item.destroy
    # 削除のあとは、グッズ一覧へ移動し、完了メッセージを表示
    # status: :see_other(303)は「次は GET で見に行ってね」の合図(DELETE のまま一覧へ行かないように)
    redirect_to goods_path, status: :see_other, notice: "グッズを消しました"
  end

  private

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
