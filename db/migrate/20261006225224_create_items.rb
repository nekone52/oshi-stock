class CreateItems < ActiveRecord::Migration[8.1]
  def change
    create_table :items do |t|
      t.string :name, null: false

      t.string :url

      t.references :category, foreign_key: true

      t.date :release_month
      t.string :release_period

      t.string :shop_name
      t.integer :price

      t.integer :quantity, default: 1, null: false

      t.integer :status, default: 0, null: false

      t.boolean :paid, default: false, null: false

      t.date :payment_deadline
      t.text :memo

      t.references :character, null: false, foreign_key: true

      t.timestamps
    end
  end
end
