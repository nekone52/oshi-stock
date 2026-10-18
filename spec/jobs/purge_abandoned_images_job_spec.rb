require "rails_helper"

RSpec.describe PurgeAbandonedImagesJob, type: :job do
  include ActiveSupport::Testing::TimeHelpers

  def put_on_shelf
    ActiveStorage::Blob.create_and_upload!(io: file_fixture("icon.png").open, filename: "icon.png", content_type: "image/png")
  end

  it "1日より前にしまって、どこにもついていない画像だけ消す" do
    old_abandoned = travel_to(2.days.ago) { put_on_shelf }
    old_attached = travel_to(2.days.ago) { put_on_shelf }
    create(:item).image.attach(old_attached)
    just_kept = put_on_shelf

    described_class.perform_now

    expect(ActiveStorage::Blob.exists?(old_abandoned.id)).to be(false)
    expect(ActiveStorage::Blob.exists?(old_attached.id)).to be(true)
    expect(ActiveStorage::Blob.exists?(just_kept.id)).to be(true)
  end
end
