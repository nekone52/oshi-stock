class GoodsController < ApplicationController
  include KeepsChosenImage

  before_action :set_item, only: [ :show, :edit, :update, :destroy, :receive, :toggle_paid, :reserve ]

  def index
    @status = params[:status] if Item.statuses.key?(params[:status])
    @items = items_for_status

    @selected_character = find_selected_character
    @items = @items.where(character: @selected_character) if @selected_character
    @query = params[:q].to_s.strip
    @items = @items.search_name(@query) if @query.present?

    @category_counts = @items.reorder(nil).group(:category_id).count
    @categories = Current.user.categories.order(:created_at)
    @selected_category = @categories.find_by(id: params[:category_id]) if params[:category_id].present?
    @items = @items.where(category: @selected_category) if @selected_category
    @wanted_groups = Item.group_by_reservation(@items) if @status == "wanted"
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
    # ほしい物リストの「諦めた」は、付せん back_to の画面(ホーム・一覧)にもどる。url_from でアプリの中の住所だけ通す
    redirect_to url_from(params[:back_to]) || helpers.back_path_for(@item), status: :see_other, notice: "グッズを消去しました"
  end

  def receive
    @item.owned!
    redirect_back_or_to root_path, celebrate: "「#{@item.name}」を所持グッズに移しました"
  end

  def reserve
    @item.reserved!
    redirect_back_or_to root_path, celebrate: "「#{@item.name}」を予約注文中に移しました"
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

  # 状態のタブでしぼる。「ほしい物」タブの1行の見た目はカテゴリを出さないので、ほかのタブのときだけカテゴリを読みこむ
  def items_for_status
    items = Current.user.items.includes(:character, image_attachment: :blob).order(created_at: :desc)
    return items.includes(:category) if @status.blank?

    items = items.where(status: @status)
    items = items.unpaid_first if @status == "reserved"
    @status == "wanted" ? items : items.includes(:category)
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
                          :status, :paid, :payment_deadline, :target_quantity, :memo, :image,
                          :reservation_start_on, :reservation_deadline_on ])
  end
end
