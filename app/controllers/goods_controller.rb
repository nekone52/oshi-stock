class GoodsController < ApplicationController
  include KeepsChosenImage

  before_action :set_item, only: [ :show, :edit, :update, :destroy, :receive, :toggle_paid ]

  def index
    @items = Current.user.items.includes(:character, :category, image_attachment: :blob).order(created_at: :desc)
    @status = params[:status] if Item.statuses.key?(params[:status])
    @items = @items.where(status: @status) if @status.present?
    @items = @items.unpaid_first if @status == "reserved"

    @selected_character = Current.user.characters.find_by(id: params[:character_id]) if params[:character_id].present?
    @items = @items.where(character: @selected_character) if @selected_character
    @query = params[:q].to_s.strip
    @items = @items.where("items.name ILIKE ?", "%#{Item.sanitize_sql_like(@query)}%") if @query.present?

    @category_counts = @items.reorder(nil).group(:category_id).count
    @categories = Current.user.categories.order(:created_at)
    @selected_category = @categories.find_by(id: params[:category_id]) if params[:category_id].present?
    @items = @items.where(category: @selected_category) if @selected_category
  end

  def show
  end

  def new
    @item = Item.new
    @item.status = params[:status] if Item.statuses.key?(params[:status])
    set_form_choices
  end

  def create
    @item = Item.new(item_params)
    assign_character_and_category
    use_kept_image(@item, :image)

    @duplicate_items = Current.user.items.includes(:character).where(name: @item.name)
    if @duplicate_items.exists? && params[:confirm_duplicate].blank?
      keep_chosen_image(@item, :image)
      set_form_choices
      render :new, status: :unprocessable_content
      return
    end

    if @item.save
      redirect_to good_path(@item), notice: "グッズを登録しました"
    else
      keep_chosen_image(@item, :image)
      set_form_choices
      render :new, status: :unprocessable_content
    end
  end

  def edit
    set_form_choices
  end

  def update
    @item.assign_attributes(item_params)
    assign_character_and_category
    use_kept_image(@item, :image)

    if @item.save
      redirect_to good_path(@item), notice: "グッズを更新しました"
    else
      keep_chosen_image(@item, :image)
      set_form_choices
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @item.destroy
    redirect_to helpers.back_path_for(@item), status: :see_other, notice: "グッズを消去しました"
  end

  def receive
    @item.owned!
    redirect_back_or_to root_path, celebrate: "「#{@item.name}」を所持グッズに移しました"
  end

  def toggle_paid
    @item.toggle!(:paid)
    if @item.paid
      redirect_back_or_to root_path, celebrate: "支払い済みにしました"
    else
      redirect_back_or_to root_path, notice: "未払いに戻しました"
    end
  end

  private

  def set_item
    @item = Current.user.items.find(params[:id])
  end

  def assign_character_and_category
    @item.character = Current.user.characters.find_by(id: params.dig(:item, :character_id))
    @item.category = Current.user.categories.find_by(id: params.dig(:item, :category_id))
  end

  def set_form_choices
    @characters = Current.user.characters.order(:created_at)
    @categories = Current.user.categories.order(:created_at)
  end

  def item_params
    params.expect(item: [ :name, :url, :release_month, :release_period, :shop_name, :price, :quantity,
                          :status, :paid, :payment_deadline, :target_quantity, :memo, :image ])
  end
end
