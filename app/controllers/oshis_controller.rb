class OshisController < ApplicationController
  # 推しキャラの一覧(ログイン中ユーザーの推しだけを、登録した順に並べる)
  def index
    # with_attached_icon:アイコン画像もまとめて取り出す(推しの数だけデータベースに聞きに行かないようにする)
    @characters = Current.user.characters.with_attached_icon.order(:created_at)
  end

  def show
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

    # データベースへの保存を試みる（バリデーションチェック）
    if @character.save
      # 保存に成功：推し一覧画面へ移動し、完了メッセージを表示
      redirect_to oshis_path, notice: "推しを登録しました！"
    else
      # 保存に失敗（名前が空など）：入力画面を再表示し、エラーメッセージを画面に残す
      render :new, status: :unprocessable_content
    end
  end

  def edit
  end

  # 削除の確認(まだモック)。後ろに推しキャラ一覧を重ねて表示するので、一覧と同じ推しを用意する
  def confirm_delete
    @characters = Current.user.characters.with_attached_icon.order(:created_at)
  end

  private

  # ストロングパラメーター：不正なデータ送信を防ぎ、許可した項目だけを取り出す安全フィルター
  def character_params
    # 送られてきたデータの中から推しキャラ情報（:character）を取り出し、名前（:name）・色（:color）・アイコン画像（:icon）だけを許可する
    params.expect(character: [ :name, :color, :icon ])
  end
end
