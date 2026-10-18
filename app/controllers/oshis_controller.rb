class OshisController < ApplicationController
  # 選んだアイコンを、エラーなどのあとも引きつぐ部品(concerns/keeps_chosen_image.rb。グッズの商品画像と同じ)
  include KeepsChosenImage

  # 1人の推しに対するアクションは、最初に「自分の推しの中から」探しておく(ほかの人の推しは見つからず 404)
  # 【自分の言葉】編集・消去の前にも、ログイン中のユーザーの推しの中から探すようにした。だから、ほかの人の推しは見られない
  before_action :set_character, only: [ :edit, :update, :confirm_delete, :destroy ]

  # 推しキャラの一覧(ログイン中ユーザーの推しだけを、登録した順に並べる)
  def index
    @characters = my_characters
    set_card_numbers
  end

  # 推し追加の画面を開く（入力フォーム用）
  def new
    # フォームを組み立てるために、ログイン中ユーザーに紐づく空の推しインスタンスを用意する
    @character = Current.user.characters.build
  end

  # 「登録する」ボタンを押したときの保存処理
  def create
    # フォームから送られた安全な値（名前・色）を受け取り、ログイン中ユーザーの推しとして組み立てる
    @character = Current.user.characters.build(character_params)
    use_kept_image(@character, :icon)

    # データベースへの保存を試みる（バリデーションチェック）
    if @character.save
      # 保存に成功：推し一覧画面へ移動し、完了メッセージを表示
      redirect_to oshis_path, notice: "推しを登録しました！"
    else
      # 保存に失敗（名前が空など）：入力画面を再表示し、エラーメッセージを画面に残す
      keep_chosen_image(@character, :icon)
      render :new, status: :unprocessable_content
    end
  end

  # 推しを編集の画面を開く(推しは before_action の set_character で探してある)
  def edit
  end

  # 「保存する」ボタンを押したときの更新処理
  def update
    # 送られてきた中身を入れる(まだ保存しない。引換券のアイコンをつけてから保存するため)
    @character.assign_attributes(character_params)
    use_kept_image(@character, :icon)
    if @character.save
      # 更新に成功:推し一覧画面へ移動し、完了メッセージを表示
      redirect_to oshis_path, notice: "推しを更新しました"
    else
      # 更新に失敗(名前が空など):編集画面を再表示し、エラーメッセージを画面に残す
      keep_chosen_image(@character, :icon)
      render :edit, status: :unprocessable_content
    end
  end

  # 消去の確認の画面を開く(消す推しは set_character で探してある)
  def confirm_delete
    # 後ろに推しキャラ一覧を重ねて表示するので、一覧と同じ推しと、名刺の数も用意する
    @characters = my_characters
    set_card_numbers
  end

  # 確認の画面で「消去する」を押したときの消去処理
  def destroy
    @character.destroy
    # 消去のあとは、一覧へ移動し、完了メッセージを表示
    # status: :see_other(303)は「次は GET で見に行ってね」の合図(DELETE のまま一覧へ行かないように)
    redirect_to oshis_path, status: :see_other, notice: "推しを消去しました"
  end

  private

  # URL の番号の推しを、ログイン中ユーザーの推しの中から探す
  def set_character
    @character = Current.user.characters.find(params[:id])
  end

  # ログイン中ユーザーの推したち(一覧と消去の確認で使う)
  # with_attached_icon:アイコン画像もまとめて取り出す(推しの数だけデータベースに聞きに行かないようにする)
  def my_characters
    Current.user.characters.with_attached_icon.order(:created_at)
  end

  # 名刺カードに出す数(推しごとの「ほしい・予約中・所持」の件数と、持っているグッズの個数)
  # 推しの数だけデータベースに聞きに行かないように、自分のグッズをまとめて2回だけ数える
  #   @status_counts:{ [推しの番号, "wanted"] => 2, … }
  #   @owned_quantities:{ 推しの番号 => 3, … }(所持のグッズの個数を足す。観賞用・保存用で2個なら2と数える)
  # 【自分の言葉】個数だけを足すと、持っている数になる(単価 × 個数 だと金額になる)
  def set_card_numbers
    @status_counts = Current.user.items.group(:character_id, :status).count
    @owned_quantities = Current.user.items.owned.group(:character_id).sum(:quantity)
  end

  # ストロングパラメーター：不正なデータ送信を防ぎ、許可した項目だけを取り出す安全フィルター
  def character_params
    # 送られてきたデータの中から推しキャラ情報（:character）を取り出し、名前（:name）・色（:color）・アイコン画像（:icon）だけを許可する
    params.expect(character: [ :name, :color, :icon ])
  end
end
