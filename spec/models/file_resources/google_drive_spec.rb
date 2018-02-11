# frozen_string_literal: true

require 'models/shared_examples/being_a_file_resource.rb'

RSpec.describe FileResources::GoogleDrive, type: :model do
  subject(:file) { build :file_resources_google_drive }

  it_should_behave_like 'being a file resource' do
    let(:file_resource) { file }
  end

  describe '#provider' do
    it { expect(file.provider).to be Providers::GoogleDrive }
  end
end
