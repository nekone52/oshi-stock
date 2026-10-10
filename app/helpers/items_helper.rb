module ItemsHelper
  # グッズの状態(enum の名前)を、画面に出す日本語にする
  STATUS_LABELS = { "wanted" => "ほしい物", "reserved" => "予約中", "owned" => "所持" }.freeze

  # 例:status_label(item) → 「予約中」
  def status_label(item)
    STATUS_LABELS[item.status]
  end

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

  # グッズの戻り先(詳細の「<」・消去のあと)。下のメニューがないので、グッズの状態で帰る一覧を決める
  # 予約中と、届いたけど未払いのもの → 予約画面(予約画面に出ているグッズと同じ)
  # ほしい物・所持(支払い済み) → グッズ一覧の、その状態でしぼった画面
  # 例:back_path_for(item) → "/reservations" や "/goods?status=wanted"
  def back_path_for(item)
    # 【自分の言葉】予約中?または(所持?かつ未払い?)→ 予約中か、届いたけど未払いのグッズなら、予約画面に戻す
    if item.reserved? || (item.owned? && !item.paid)
      reservations_path
    else
      goods_path(status: item.status)
    end
  end

  # 支払い期限が7日以内(または、すぎている)か。目立たせるために使う
  def payment_due_soon?(item)
    item.payment_deadline.present? && item.payment_deadline <= 7.days.from_now.to_date
  end
end
