module ItemsHelper
  # 発売の時期を、画面に出す文字にする(例:「10月上旬予定」「発売 未定」)
  def release_label(item)
    return "発売 未定" if item.release_month.blank?

    "#{item.release_month.month}月#{item.release_period}予定"
  end

  # 支払い期限を、画面に出す文字にする(例:「支払期限 10/8(あと4日)」「支払期限 未定」)
  def payment_deadline_label(item)
    return "支払期限 未定" if item.payment_deadline.blank?

    days = (item.payment_deadline - Date.current).to_i
    rest = if days.positive? then "あと#{days}日"
    elsif days.zero? then "今日まで"
    else "#{-days}日すぎています"
    end
    "支払期限 #{item.payment_deadline.month}/#{item.payment_deadline.day}(#{rest})"
  end

  # 商品ページの URL が、http か https で始まる安全なものなら、その URL を返す(それ以外は nil)
  # モデルでも同じチェックをしているが、画面でも確かめて、javascript: などの危ない URL をリンクにしない
  def safe_item_url(item)
    uri = URI.parse(item.url.to_s)
    uri.to_s if uri.is_a?(URI::HTTP) && uri.host.present?
  rescue URI::InvalidURIError
    nil
  end

  # 支払い期限が7日以内(または、すぎている)か。目立たせるために使う
  def payment_due_soon?(item)
    item.payment_deadline.present? && item.payment_deadline <= 7.days.from_now.to_date
  end
end
