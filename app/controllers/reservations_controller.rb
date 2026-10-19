class ReservationsController < ApplicationController
  def index
    @reserved_items = Current.user.items.reserved_or_unpaid
                                  .includes(:character, image_attachment: :blob).unpaid_first
    @reserved_count = @reserved_items.size
    @unpaid_total   = Current.user.unpaid_total
    @unpaid_count   = Current.user.unpaid_items.count
    @due_soon_count = Current.user.due_soon_count
    @selected_character = Current.user.characters.find_by(id: params[:character_id]) if params[:character_id].present?
    @reserved_items = @reserved_items.where(character: @selected_character) if @selected_character
    @reserved_items = @reserved_items.where(paid: false) if params[:filter] == "unpaid"
    @reserved_items = @reserved_items.where(paid: true) if params[:filter] == "paid"
    @reserved_items = @reserved_items.owned.where(paid: false) if params[:filter] == "arrived"
    items_by_month = @reserved_items.group_by(&:release_month)
    @waiting_items  = items_by_month.delete(nil) || []
    @items_by_month = items_by_month.sort_by { |release_month, _items| release_month }
    @month_totals = @items_by_month.to_h.transform_values do |items|
      items.sum { |item| item.price.to_i * item.quantity }
    end
  end
end
