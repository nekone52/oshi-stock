class TopController < ApplicationController
  def index
    @characters = Current.user.characters.with_attached_icon.order(:created_at)
    return render :start if @characters.empty?

    @items = Current.user.items.includes(:character, image_attachment: :blob).order(created_at: :desc)
    @selected_character = @characters.find_by(id: params[:character_id]) if params[:character_id].present?
    @items = @items.where(character: @selected_character) if @selected_character
    @query = params[:q].to_s.strip
    @items = @items.search_name(@query) if @query.present?

    @wanted_items   = @items.wanted
    @reserved_items = @items.reserved.or(@items.owned.where(paid: false)).unpaid_first
    @owned_items    = @items.owned

    @unpaid_total   = Current.user.unpaid_total
    @unpaid_count   = Current.user.unpaid_items.count
    @due_soon_count = Current.user.due_soon_count
  end

  def start
  end
end
