module ThemeHelper
  DEFAULT_THEME_COLOR = "#E8577A".freeze
  THEME_SWATCHES = [
    [ "ローズ", "#E8577A" ], [ "コーラル", "#E2726A" ], [ "ルビー", "#C0304A" ], [ "クリムゾン", "#A8233A" ],
    [ "アプリコット", "#E08A4A" ], [ "テラコッタ", "#B8603E" ], [ "アンバー", "#D99A1E" ], [ "マスタード", "#B8901F" ],
    [ "ライム", "#8DB33A" ], [ "オリーブ", "#6F7E34" ], [ "エメラルド", "#2E9E73" ], [ "フォレスト", "#3C6E4A" ],
    [ "スカイ", "#5AA9D6" ], [ "シアン", "#2A9DB0" ], [ "ロイヤルブルー", "#3B4FC4" ], [ "コバルト", "#2F5DAA" ],
    [ "ラベンダー", "#8C79B8" ], [ "バイオレット", "#7A4FB8" ], [ "キャメル", "#B08050" ], [ "チョコ", "#6E4A36" ],
    [ "グレー", "#7A7A86" ], [ "チャコール", "#3F3F4A" ], [ "シルバー", "#A9AEB8" ], [ "ペールグレー", "#C9CCD3" ]
  ].freeze
  WHITE = [ 255, 255, 255 ].freeze
  INK = [ 43, 30, 42 ].freeze

  def theme_style
    color = Current.user&.theme_color
    return if color.blank? || !color.match?(/\A#\h{6}\z/) || color.casecmp?(DEFAULT_THEME_COLOR)

    base = hex_to_rgb(color)
    [
      "--color-accent: #{color}",
      "--color-accent-strong: #{rgb_to_hex(mix(base, INK, 0.35))}",
      "--color-accent-soft: #{rgb_to_hex(mix(base, WHITE, 0.82))}",
      "--color-on-accent: #{contrast(base, WHITE) >= 3 ? '#FFFFFF' : '#2B1E2A'}"
    ].join("; ")
  end

  private

  # "#E8577A" → [232, 87, 122]
  def hex_to_rgb(hex)
    hex.delete("#").scan(/../).map { |pair| pair.to_i(16) }
  end

  # [232, 87, 122] → "#E8577A"
  def rgb_to_hex(rgb)
    "#" + rgb.map { |value| value.round.clamp(0, 255).to_s(16).rjust(2, "0") }.join.upcase
  end

  def mix(a, b, rate)
    a.zip(b).map { |x, y| x * (1 - rate) + y * rate }
  end

  def luminance(rgb)
    r, g, b = rgb.map do |value|
      value /= 255.0
      value <= 0.03928 ? value / 12.92 : ((value + 0.055) / 1.055)**2.4
    end
    0.2126 * r + 0.7152 * g + 0.0722 * b
  end

  def contrast(a, b)
    lighter, darker = [ luminance(a), luminance(b) ].sort.reverse
    (lighter + 0.05) / (darker + 0.05)
  end
end
