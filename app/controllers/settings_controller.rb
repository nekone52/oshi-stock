class SettingsController < ApplicationController
  def show
  end

  def update
    if Current.user.update(theme_params)
      redirect_to settings_path, notice: "テーマの色を変えました"
    else
      render :show, status: :unprocessable_content
    end
  end

  def edit_email
  end

  def update_email
    if Current.user.update(email_params)
      redirect_to settings_path, notice: "メールアドレスを変えました"
    else
      render :edit_email, status: :unprocessable_content
    end
  end

  def withdraw
  end

  def destroy
    user = Current.user
    terminate_session
    user.destroy
    redirect_to new_session_path, notice: "退会しました。ご利用ありがとうございました"
  end

  private

  def theme_params
    params.expect(user: [ :theme_color ])
  end

  def email_params
    attributes = params.expect(user: [ :email_address, :password_challenge ])
    attributes[:password_challenge] = attributes[:password_challenge].to_s
    attributes
  end
end
