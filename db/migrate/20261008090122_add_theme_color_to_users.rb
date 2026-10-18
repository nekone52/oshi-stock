class AddThemeColorToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :theme_color, :string, null: false, default: "#E8577A"
  end
end
