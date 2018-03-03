# frozen_string_literal: true

require 'models/shared_examples/being_a_file_resource.rb'
require 'models/shared_examples/being_resourceable.rb'
require 'models/shared_examples/being_snapshotable.rb'
require 'models/shared_examples/being_stageable.rb'
require 'models/shared_examples/being_syncable.rb'

RSpec.describe FileResources::GoogleDrive, type: :model do
  subject(:file) { build :file_resources_google_drive }

  it_should_behave_like 'being a file resource' do
    let(:file_resource) { file }
    let(:mime_type_class) { Providers::GoogleDrive::MimeType }
  end

  it_should_behave_like 'being resourceable' do
    let(:resourceable) { file }
    let(:icon_class)      { Providers::GoogleDrive::Icon }
    let(:link_class)      { Providers::GoogleDrive::Link }
    let(:mime_type_class) { Providers::GoogleDrive::MimeType }
  end

  it_should_behave_like 'being snapshotable' do
    let(:snapshotable) { file }
  end

  it_should_behave_like 'being stageable' do
    let(:stageable) { file }
  end

  it_should_behave_like 'being syncable' do
    let(:syncable) { file }
  end

  describe '#provider' do
    it { expect(file.provider).to be Providers::GoogleDrive }
  end
end
