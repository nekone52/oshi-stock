class AddThemeColorToUsers < ActiveRecord::Migration[8.1]
  def change
    # 【テーマの色】ボタン・リンクなどのアクセントの色(「#」+ 16進数6桁)
    # 空っぽ禁止。今いるユーザーと、何も選んでいない人は、アプリのピンク(#E8577A)が自動で入る
    add_column :users, :theme_color, :string, null: false, default: "#E8577A"
  end
end
