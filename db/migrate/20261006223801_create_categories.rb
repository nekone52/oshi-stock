class CreateCategories < ActiveRecord::Migration[8.1]
  def change
    create_table :categories do |t|
      t.string :name, null: false
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
    # 同じユーザーの中で、同じ名前のカテゴリは1つだけ(ちがうユーザーなら同じ名前でもOK)
    add_index :categories, [ :user_id, :name ], unique: true
  end
end
