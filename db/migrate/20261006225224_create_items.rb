class CreateItems < ActiveRecord::Migration[8.1]
  def change
    create_table :items do |t|
      # 【グッズ名】空っぽ（未入力）はダメなので null: false
      t.string :name, null: false

      # 【商品URL】なくてもいいので空OK
      t.string :url

      # 【カテゴリ】カテゴリを削除した時に「グッズは残してここだけ空にする」ため null: false は外す
      t.references :category, foreign_key: true

      # 【発売年月・時期】「2026年10月（日は1日で保存）」「上旬」などを入れる（空OK）
      t.date :release_month
      t.string :release_period

      # 【購入店舗・価格】ショップ名（空OK）と 単価（税込・円 / 空OK）
      t.string :shop_name
      t.integer :price

      # 【個数】未入力なら「1個」にしたいので、初期値を1にして空っぽ禁止にする
      t.integer :quantity, default: 1, null: false

      # 【状態】「欲しい/予約中/所持」を番号で管理（最初は「欲しい」の0番を入れるため初期値0）
      t.integer :status, default: 0, null: false

      # 【支払い済みか】最初は「未払い（false）」にしておきたいので、初期値false
      t.boolean :paid, default: false, null: false

      # 【支払い期限・メモ】期限が近いものを目立たせる日付（空OK）と 自由なメモ欄（空OK）
      t.date :payment_deadline
      t.text :memo

      # 【誰のグッズか】キャラクターとの紐付け（必ずどれかのキャラに属するので空っぽ禁止）
      t.references :character, null: false, foreign_key: true

      # 作成日時（created_at）と更新日時（updated_at）を自動で作るRailsのお決まり
      t.timestamps
    end
  end
end
