require "rails_helper"

RSpec.describe OshiColor do
  describe ".soften" do
    it "おすすめの24色は、どれも直さずにそのまま" do
      ThemeHelper::THEME_SWATCHES.each do |name, color|
        expect(described_class.soften(color)).to eq(color), "#{name}(#{color})が変わってしまった"
      end
    end

    it "明るすぎる色は、落ち着いた色に直す" do
      expect(described_class.soften("#FFFF00")).to eq("#B8B521")
      expect(described_class.soften("#FFFFFF")).to eq("#CCC9CC")
    end

    it "暗すぎる色は、見えるくらいに明るくする" do
      expect(described_class.soften("#000000")).to eq("#3D3D3D")
    end

    it "鮮やかすぎる青は、チカチカしないようにおさえる" do
      expect(described_class.soften("#0000FF")).to eq("#3333CC")
    end

    it "色の形でない値は、そのまま返す(チェックはバリデーションの係)" do
      expect(described_class.soften("")).to eq("")
      expect(described_class.soften(nil)).to be_nil
      expect(described_class.soften("red")).to eq("red")
    end
  end
end
