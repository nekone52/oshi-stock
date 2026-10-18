require "rails_helper"

# Codex の指摘③:登録をやめると、しまった画像が棚に残りつづけていた
RSpec.describe PurgeAbandonedImagesJob, type: :job do
  include ActiveSupport::Testing::TimeHelpers

  # 棚(Active Storage)に画像を1つしまう
  def put_on_shelf
    ActiveStorage::Blob.create_and_upload!(io: file_fixture("icon.png").open, filename: "icon.png", content_type: "image/png")
  end

  it "1日より前にしまって、どこにもついていない画像だけ消す" do
    old_abandoned = travel_to(2.days.ago) { put_on_shelf }
    old_attached = travel_to(2.days.ago) { put_on_shelf }
    create(:item).image.attach(old_attached)
    just_kept = put_on_shelf

    described_class.perform_now

    expect(ActiveStorage::Blob.exists?(old_abandoned.id)).to be(false) # 迷子 → 消える
    expect(ActiveStorage::Blob.exists?(old_attached.id)).to be(true)   # グッズについている → 残る
    expect(ActiveStorage::Blob.exists?(just_kept.id)).to be(true)      # しまったばかり(まだ引換券が使える) → 残る
  end
end
