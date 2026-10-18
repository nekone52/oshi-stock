module ItemsHelper
  STATUS_LABELS = { "wanted" => "ほしい物", "reserved" => "予約中", "owned" => "所持" }.freeze

  def status_label(item)
    STATUS_LABELS[item.status]
  end

  def release_label(item)
    return "発売 未定" if item.release_month.blank?

    "#{item.release_month.month}月#{item.release_period}予定"
  end

  def payment_deadline_label(item)
    return "支払期限 未定" if item.payment_deadline.blank?

    days = (item.payment_deadline - Date.current).to_i
    rest = if days.positive? then "あと#{days}日"
    elsif days.zero? then "今日まで"
    else "#{-days}日すぎています"
    end
    "支払期限 #{item.payment_deadline.month}/#{item.payment_deadline.day}(#{rest})"
  end

  def safe_item_url(item)
    uri = URI.parse(item.url.to_s)
    uri.to_s if uri.is_a?(URI::HTTP) && uri.host.present?
  rescue URI::InvalidURIError
    nil
  end

  def item_url_label(item)
    URI.parse(item.url.to_s).host.to_s.delete_prefix("www.")
  rescue URI::InvalidURIError
    ""
  end

  def back_path_for(item)
    if item.reserved? || (item.owned? && !item.paid)
      reservations_path
    else
      goods_path(status: item.status)
    end
  end

  def payment_due_soon?(item)
    item.payment_deadline.present? && item.payment_deadline <= 7.days.from_now.to_date
  end
end
