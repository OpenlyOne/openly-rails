# frozen_string_literal: true

RSpec.describe FileResource, type: :model do
  subject(:file) { build :file_resource }

  describe '.entities' do
    subject(:entities) { FileResource.entities }
    it { expect(entities.values).to include FileResources::GoogleDrive }
  end
end
