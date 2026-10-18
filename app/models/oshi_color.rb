module OshiColor
  INK = [ 43, 30, 42 ].freeze
  WHITE = [ 255, 255, 255 ].freeze

  MAX_SATURATION = 0.76
  MAX_SATURATION_BLUE = 0.6
  MIN_LUMINANCE = 0.04
  MAX_LUMINANCE = 0.45
  MAX_LUMINANCE_GRAY = 0.62

  module_function

  def soften(hex)
    return hex unless hex.is_a?(String) && hex.match?(/\A#\h{6}\z/)

    hue, saturation, lightness = to_hsl(hex)
    limit = (200..290).cover?(hue) ? MAX_SATURATION_BLUE : MAX_SATURATION
    base = saturation > limit ? to_rgb(hue, limit, lightness) : hex_to_rgb(hex)

    max_luminance = saturation < 0.15 ? MAX_LUMINANCE_GRAY : MAX_LUMINANCE
    color = base
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

  def mix(a, b, rate)
    a.zip(b).map { |x, y| (x * (1 - rate) + y * rate).round }
  end

  def luminance(rgb)
    r, g, b = rgb.map do |value|
      value /= 255.0
      value <= 0.03928 ? value / 12.92 : ((value + 0.055) / 1.055)**2.4
    end
    0.2126 * r + 0.7152 * g + 0.0722 * b
  end

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

  def to_rgb(hue, saturation, lightness)
    a = saturation * [ lightness, 1 - lightness ].min
    [ 0, 8, 4 ].map do |n|
      k = (n + hue / 30) % 12
      ((lightness - a * [ -1, [ k - 3, 9 - k, 1 ].min ].max) * 255).round
    end
  end
end
