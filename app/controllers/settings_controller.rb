class SettingsController < ApplicationController
  def show
  end

  # 【テーマの色を保存する】PATCH /settings
  # 【自分の言葉】ユーザーを絞って(ログインしている本人だけ)、テーマの色を保存する。
  # 保存できたら設定画面に戻ってお知らせを出し、入力が違えば「違うよ」と表示する
  def update
    if Current.user.update(theme_params)
      # 保存できた:設定画面に戻って、お知らせを出す
      redirect_to settings_path, notice: "テーマの色を変えました"
    else
      # 保存できなかった(色の形がちがうなど):設定画面をもう一度出して、エラーを見せる
      render :show, status: :unprocessable_content
    end
  end

  def withdraw
  end

  private

  # 送られてきたデータの中からユーザー情報(:user)を取り出し、テーマの色(:theme_color)だけを許可する
  def theme_params
    params.expect(user: [ :theme_color ])
  end
end
