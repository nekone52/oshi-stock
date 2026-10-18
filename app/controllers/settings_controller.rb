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

  # 【メールアドレスを変える画面】GET /settings/email
  def edit_email
  end

  # 【メールアドレスを書きかえる】PATCH /settings/email
  # Current.user … ログインしている本人のメールアドレスだけを書きかえる(ほかの人のは変えられない)
  # password_challenge … 今のパスワード。has_secure_password の仕組みで、合っていなければ保存しない
  def update_email
    if Current.user.update(email_params)
      redirect_to settings_path, notice: "メールアドレスを変えました"
    else
      # 保存できなかった(パスワードがちがう・形がちがう・ほかの人と同じなど):画面をもう一度出して、エラーを見せる
      render :edit_email, status: :unprocessable_content
    end
  end

  def withdraw
  end

  # 【退会する】DELETE /settings/withdraw
  def destroy
    user = Current.user
    # 先にログアウトする(ブラウザの鍵も消す)。あとにすると、ログインの記録がユーザーと一緒に消えてしまう
    terminate_session
    # 【自分の言葉】destroy は未練なしに割り切る(推し・グッズ・カテゴリ・画像も、まとめて全部消す)
    user.destroy
    redirect_to new_session_path, notice: "退会しました。ご利用ありがとうございました"
  end

  private

  # 送られてきたデータの中からユーザー情報(:user)を取り出し、テーマの色(:theme_color)だけを許可する
  def theme_params
    params.expect(user: [ :theme_color ])
  end

  # 送られてきたデータの中から、新しいメールアドレス(:email_address)と今のパスワード(:password_challenge)だけを許可する
  # 今のパスワードが送られてこないと確かめがとばされてしまうので、空っぽでも必ず確かめる(空なら「ちがう」になる)
  def email_params
    attributes = params.expect(user: [ :email_address, :password_challenge ])
    attributes[:password_challenge] = attributes[:password_challenge].to_s
    attributes
  end
end
