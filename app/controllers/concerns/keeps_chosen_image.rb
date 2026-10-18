# 【選んだ画像を、棚にしまって引きつぐ部品】グッズの商品画像・推しのアイコンで使う
# 画像を選ぶ欄は、ブラウザの決まりでサーバーから中身を入れられない。なので、エラーなどで画面をもう一度出すと、選んだ画像が消えてしまう
# そこで、届いた画像を先に Active Storage(棚)にしまい、フォームには引換券(@kept_image)だけを入れておく。2回目の送信で引換券から画像をつける
# 【自分の言葉】画像を棚にしまって、封筒(フォーム)に引換券を入れる
module KeepsChosenImage
  extend ActiveSupport::Concern

  # しまってよい画像(モデルのチェックとそろえる。item.rb・character.rb)
  KEPT_IMAGE_TYPES = %w[image/jpeg image/png image/webp].freeze
  KEPT_IMAGE_MAX_SIZE = 5.megabytes
  # 引換券が使える時間
  KEPT_IMAGE_EXPIRES_IN = 1.hour

  private

  # 【画面をもう一度出す前に】今回選ばれた画像を棚にしまって、引換券を @kept_image に入れる
  # record = グッズや推し、name = :image や :icon
  def keep_chosen_image(record, name)
    change = record.attachment_changes[name.to_s]
    return unless change # 今回、画像が選ばれていない(今の画像のまま)なら、何もしない

    blob = change.blob
    unless blob.persisted?
      # 形式・大きさがだめな画像はしまわない(画面にはモデルのエラーが出る)
      return unless blob.content_type.in?(KEPT_IMAGE_TYPES) && blob.byte_size < KEPT_IMAGE_MAX_SIZE

      file = change.attachable
      file.rewind
      blob = ActiveStorage::Blob.create_and_upload!(io: file, filename: blob.filename, content_type: blob.content_type)
      record.public_send("#{name}=", blob)
      # ついでに、ずっと前にしまったまま使われなかった画像を片づける(purge_abandoned_images_job.rb)
      PurgeAbandonedImagesJob.perform_later
    end
    # 引換券に「だれ用か(purpose)」と「使える時間(expires_in)」を入れる。ほかの人や、時間切れの引換券は使えない
    @kept_image = blob.signed_id(purpose: kept_image_purpose, expires_in: KEPT_IMAGE_EXPIRES_IN)
  end

  # 【2回目の送信で】新しい画像が選ばれていなければ、引換券の画像をつける
  # find_signed は、書きかえた・ほかの人用の・時間切れの引換券なら nil を返す
  # どこにもついていない(しまっただけの)画像だけ使う。ほかのグッズの画像を横取りしないため
  def use_kept_image(record, name)
    return if params[:kept_image].blank? || record.attachment_changes[name.to_s]

    blob = ActiveStorage::Blob.find_signed(params[:kept_image], purpose: kept_image_purpose)
    record.public_send("#{name}=", blob) if blob && blob.attachments.none?
  end

  # 引換券の「だれ用か」。ログイン中の人の番号を入れる
  def kept_image_purpose
    "kept_image_for_user_#{Current.user.id}"
  end
end
