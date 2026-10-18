require "rails_helper"

RSpec.describe "← ホーム", type: :request do
  let(:user) { create(:user) }

  before { sign_in_as(user) }

  %w[/goods /oshis /reservations /settings].each do |path|
    it "#{path} に「← ホーム」があって、ホームへ戻れる" do
      get path

      expect(response.body).to include(%(<span aria-hidden="true">←</span> ホーム), %(href="#{root_path}"))
    end
  end

  %w[/goods /reservations].each do |path|
    it "#{path} で推しを選んでいたら、「← ホーム」にその推しの番号がつく" do
      character = create(:character, user: user)
      get "#{path}?character_id=#{character.id}"

      expect(response.body).to include(%(href="#{root_path(character_id: character.id)}"))
    end
  end
end
