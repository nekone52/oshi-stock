class OshisController < ApplicationController
  include KeepsChosenImage

  before_action :set_character, only: [ :edit, :update, :confirm_delete, :destroy ]

  def index
    @characters = my_characters
    set_card_numbers
  end

  def new
    @character = Current.user.characters.build
  end

  def create
    @character = Current.user.characters.build(character_params)
    use_kept_image(@character, :icon)

    if @character.save
      redirect_to oshis_path, notice: "推しを登録しました！"
    else
      keep_chosen_image(@character, :icon)
      render :new, status: :unprocessable_content
    end
  end

  def edit
  end

  def update
    @character.assign_attributes(character_params)
    use_kept_image(@character, :icon)
    if @character.save
      redirect_to oshis_path, notice: "推しを更新しました"
    else
      keep_chosen_image(@character, :icon)
      render :edit, status: :unprocessable_content
    end
  end

  def confirm_delete
    @characters = my_characters
    set_card_numbers
  end

  def destroy
    @character.destroy
    redirect_to oshis_path, status: :see_other, notice: "推しを消去しました"
  end

  private

  def set_character
    @character = Current.user.characters.find(params[:id])
  end

  def my_characters
    Current.user.characters.with_attached_icon.order(:created_at)
  end

  def set_card_numbers
    @status_counts = Current.user.items.group(:character_id, :status).count
    @owned_quantities = Current.user.items.owned.group(:character_id).sum(:quantity)
  end

  def character_params
    params.expect(character: [ :name, :color, :icon ])
  end
end
