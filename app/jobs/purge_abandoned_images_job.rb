class PurgeAbandonedImagesJob < ApplicationJob
  queue_as :default

  def perform
    ActiveStorage::Blob.unattached.where(created_at: ...1.day.ago).find_each(&:purge)
  end
end
