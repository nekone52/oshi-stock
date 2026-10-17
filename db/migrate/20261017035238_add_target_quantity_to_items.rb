class AddTargetQuantityToItems < ActiveRecord::Migration[8.1]
  def change
    # グッズの目標個数(観賞用・保存用・布教用など、何個ほしいか)。#62
    # 空っぽ(null)= 目標なし(入力画面のスイッチがオフ)なので、null: false も default もつけない
    # 確保した数は、いまある quantity(個数)を使う
    # 【自分の言葉】目標個数をデータとして残す(グッズの棚に、しまう場所を足す。空っぽでもOK)
    add_column :items, :target_quantity, :integer
  end
end
