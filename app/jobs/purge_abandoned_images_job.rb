# 【迷子の画像の片づけ係】登録をやめたなどで、しまったまま使われなかった画像を消す
# 引換券は1時間で使えなくなるので、1日より前にしまって、どこにもついていない画像は、もう使われない
# 定期的に動かすしくみ(Render の無料プランにはない)のかわりに、新しく画像をしまうときに、ついでに動かす(keeps_chosen_image.rb)
class PurgeAbandonedImagesJob < ApplicationJob
  queue_as :default

  def perform
    ActiveStorage::Blob.unattached.where(created_at: ...1.day.ago).find_each(&:purge)
  end
end
