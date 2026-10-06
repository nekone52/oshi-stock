class PagesController < ApplicationController
  # 利用規約・プライバシーポリシーは、新規登録の前に読めるようにログインなしで開ける
  allow_unauthenticated_access

  def terms
  end

  def privacy
  end
end
