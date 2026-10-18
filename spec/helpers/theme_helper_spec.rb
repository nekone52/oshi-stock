require "rails_helper"

RSpec.describe ThemeHelper, type: :helper do
  def sign_in_with_color(color)
    Current.session = Session.new(user: build(:user, theme_color: color))
  end

  after { Current.reset }

  it "ログインしていなければ、何も上書きしない" do
    expect(helper.theme_style).to be_nil
  end

  it "最初のピンクなら、何も上書きしない" do
    sign_in_with_color("#E8577A")
    expect(helper.theme_style).to be_nil
  end

  it "濃い色(青)なら、ボタンの文字は白" do
    sign_in_with_color("#4E6FA3")
    expect(helper.theme_style).to include("--color-accent: #4E6FA3", "--color-on-accent: #FFFFFF")
  end

  it "明るい色(黄)なら、ボタンの文字は黒(読みやすくするため)" do
    sign_in_with_color("#F5D03B")
    expect(helper.theme_style).to include("--color-on-accent: #2B1E2A")
  end

  it "色の形でない値は、画面の style に入れない" do
    sign_in_with_color("red; display: none")
    expect(helper.theme_style).to be_nil
  end
end
