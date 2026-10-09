# 【推しの色のお掃除係】明るすぎ・暗すぎ・ギラギラの色を、おすすめの24色と同じくらいの落ち着いた色に直す
# 推しの色(Character#color)と、テーマの色(User#theme_color)の normalizes で使う
# おすすめの24色は、どれも直す必要がない色にしてある(spec/models/oshi_color_spec.rb で確かめている)
module OshiColor
  INK = [ 43, 30, 42 ].freeze      # 文字の黒(--color-ink)。明るすぎる色にまぜて落ち着かせる
  WHITE = [ 255, 255, 255 ].freeze # 暗すぎる色にまぜて明るくする

  # 鮮やかさの上限(0〜1)。青〜紫(色み 200〜290度)は目がチカチカしやすいので、ほかより低くする
  MAX_SATURATION = 0.76
  MAX_SATURATION_BLUE = 0.6
  # 人の目に見える明るさのはば(0 = 黒 〜 1 = 白)。グレー系(ほぼ色みがない色)だけ、白っぽい色まで使える
  MIN_LUMINANCE = 0.04
  MAX_LUMINANCE = 0.45
  MAX_LUMINANCE_GRAY = 0.62

  module_function

  # "#FFFF00" → "#B8B521" のように直す。形がちがう値(空っぽなど)は、そのまま返す(チェックはバリデーションの係)
  def soften(hex)
    return hex unless hex.is_a?(String) && hex.match?(/\A#\h{6}\z/)

    hue, saturation, lightness = to_hsl(hex)
    limit = (200..290).cover?(hue) ? MAX_SATURATION_BLUE : MAX_SATURATION
    # 鮮やかすぎるときだけ、鮮やかさを上限まで下げる
    base = saturation > limit ? to_rgb(hue, limit, lightness) : hex_to_rgb(hex)

    max_luminance = saturation < 0.15 ? MAX_LUMINANCE_GRAY : MAX_LUMINANCE
    color = base
    # 明るすぎるときは黒を、暗すぎるときは白を、少しずつ(2%ずつ)まぜて、はばの中に入れる
    0.step(1, 0.02) { |rate| break if luminance(color) <= max_luminance; color = mix(base, INK, rate) }
    0.step(1, 0.02) { |rate| break if luminance(color) >= MIN_LUMINANCE; color = mix(base, WHITE, rate) }

    color == hex_to_rgb(hex) ? hex : rgb_to_hex(color)
  end

  # "#E8577A" → [232, 87, 122]
  def hex_to_rgb(hex)
    hex.delete("#").scan(/../).map { |pair| pair.to_i(16) }
  end

  # [232, 87, 122] → "#E8577A"
  def rgb_to_hex(rgb)
    "#" + rgb.map { |value| value.round.clamp(0, 255).to_s(16).rjust(2, "0") }.join.upcase
  end

  # 2つの色を、rate の割合でまぜる(rate が 0 なら a のまま、1 なら b)。まぜたあとは整数にそろえる
  def mix(a, b, rate)
    a.zip(b).map { |x, y| (x * (1 - rate) + y * rate).round }
  end

  # 人の目に見える明るさ(0 = 黒 〜 1 = 白)。theme_helper.rb の luminance と同じ計算
  def luminance(rgb)
    r, g, b = rgb.map do |value|
      value /= 255.0
      value <= 0.03928 ? value / 12.92 : ((value + 0.055) / 1.055)**2.4
    end
    0.2126 * r + 0.7152 * g + 0.0722 * b
  end

  # "#FFFF00" → [色み(0〜360度), 鮮やかさ(0〜1), 明るさ(0〜1)]
  def to_hsl(hex)
    r, g, b = hex_to_rgb(hex).map { |value| value / 255.0 }
    max, min = [ r, g, b ].max, [ r, g, b ].min
    lightness = (max + min) / 2
    return [ 0, 0, lightness ] if max == min

    diff = max - min
    saturation = lightness > 0.5 ? diff / (2 - max - min) : diff / (max + min)
    hue = case max
    when r then (g - b) / diff + (g < b ? 6 : 0)
    when g then (b - r) / diff + 2
    else (r - g) / diff + 4
    end
    [ hue * 60, saturation, lightness ]
  end

  # 色み・鮮やかさ・明るさ → [r, g, b](整数)
  def to_rgb(hue, saturation, lightness)
    a = saturation * [ lightness, 1 - lightness ].min
    [ 0, 8, 4 ].map do |n|
      k = (n + hue / 30) % 12
      ((lightness - a * [ -1, [ k - 3, 9 - k, 1 ].min ].max) * 255).round
    end
  end
end
