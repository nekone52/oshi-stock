module KeepsChosenImage
  extend ActiveSupport::Concern

  KEPT_IMAGE_TYPES = %w[image/jpeg image/png image/webp].freeze
  KEPT_IMAGE_MAX_SIZE = 5.megabytes
  KEPT_IMAGE_EXPIRES_IN = 1.hour

  private

  def keep_chosen_image(record, name)
    change = record.attachment_changes[name.to_s]
    return unless change

    blob = change.blob
    unless blob.persisted?
      return unless blob.content_type.in?(KEPT_IMAGE_TYPES) && blob.byte_size < KEPT_IMAGE_MAX_SIZE

      file = change.attachable
      file.rewind
      blob = ActiveStorage::Blob.create_and_upload!(io: file, filename: blob.filename, content_type: blob.content_type)
      record.public_send("#{name}=", blob)
      PurgeAbandonedImagesJob.perform_later
    end
    @kept_image = blob.signed_id(purpose: kept_image_purpose, expires_in: KEPT_IMAGE_EXPIRES_IN)
  end

  def use_kept_image(record, name)
    return if params[:kept_image].blank? || record.attachment_changes[name.to_s]

    blob = ActiveStorage::Blob.find_signed(params[:kept_image], purpose: kept_image_purpose)
    record.public_send("#{name}=", blob) if blob && blob.attachments.none?
  end

  def kept_image_purpose
    "kept_image_for_user_#{Current.user.id}"
  end
end
