class AddTargetQuantityToItems < ActiveRecord::Migration[8.1]
  def change
    add_column :items, :target_quantity, :integer
  end
end
