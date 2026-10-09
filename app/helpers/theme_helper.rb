# 【テーマの色】ログインしている人が選んだ色で、アプリのアクセント色(ボタン・リンクなど)を入れかえる
# レイアウトの <body style="..."> に入れて、application.css の色の入れ物(--color-accent など)を上書きする
module ThemeHelper
  # 最初のピンク(この色のときは、application.css の色をそのまま使う)
  DEFAULT_THEME_COLOR = "#E8577A".freeze
  # 設定画面の「推しの色(おすすめ)」に並べる9色。推しのメンバーカラーを、ベージュの背景になじむように、くすませたもの
  THEME_SWATCHES = [
    [ "ピンク", "#E8577A" ], [ "赤", "#C4545A" ], [ "オレンジ", "#D9884E" ], [ "黄", "#D9B44A" ], [ "緑", "#6E9B6B" ],
    [ "水色", "#7FB3C8" ], [ "青", "#4E6FA3" ], [ "紫", "#8A6FB8" ], [ "チャコール", "#4A4A55" ]
  ].freeze
  WHITE = [ 255, 255, 255 ].freeze
  INK = [ 43, 30, 42 ].freeze # 文字の黒(--color-ink)

  # 色の入れ物を上書きする文字列。ログインしていない・最初のピンクのときは何も返さない
  def theme_style
    color = Current.user&.theme_color
    # 🛡️ style に入れるので、「#」+ 16進数6けた の形のときだけ使う(それ以外の文字を入れさせない)
    return if color.blank? || !color.match?(/\A#\h{6}\z/) || color.casecmp?(DEFAULT_THEME_COLOR)

    base = hex_to_rgb(color)
    [
      "--color-accent: #{color}",
      # リンクの文字など。白い背景でも読めるように、黒を35%まぜて濃くする
      "--color-accent-strong: #{rgb_to_hex(mix(base, INK, 0.35))}",
      # うすい背景(「今月」のラベルなど)。白を82%まぜてうすくする
      "--color-accent-soft: #{rgb_to_hex(mix(base, WHITE, 0.82))}",
      # ボタンの文字。白い文字が読めるうち(コントラスト3以上)は白、読めないほど明るい色のときだけ黒
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

  # 2つの色を、rate の割合でまぜる(rate が 0 なら a のまま、1 なら b)
  def mix(a, b, rate)
    a.zip(b).map { |x, y| x * (1 - rate) + y * rate }
  end

  # 色の明るさ(人の目に見える明るさ。0 = 黒 〜 1 = 白)
  def luminance(rgb)
    r, g, b = rgb.map do |value|
      value /= 255.0
      value <= 0.03928 ? value / 12.92 : ((value + 0.055) / 1.055)**2.4
    end
    0.2126 * r + 0.7152 * g + 0.0722 * b
  end

  # 2つの色の、見分けやすさ(1 = 同じ 〜 21 = 白と黒)
  def contrast(a, b)
    lighter, darker = [ luminance(a), luminance(b) ].sort.reverse
    (lighter + 0.05) / (darker + 0.05)
  end
end
