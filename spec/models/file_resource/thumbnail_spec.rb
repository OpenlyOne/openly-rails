# frozen_string_literal: true

RSpec.describe FileResource::Thumbnail, type: :model do
  subject(:thumbnail) { build :file_resource_thumbnail }

  it { should have_attached_file(:image) }

  describe 'validations' do
    it { is_expected.to validate_attachment_presence(:image) }
    it do
      is_expected
        .to validate_attachment_content_type(:image)
        .allowing('image/png', 'image/gif', 'image/jpeg')
        .rejecting('text/plain', 'text/xml')
    end
    it do
      is_expected
        .to validate_attachment_size(:image)
        .less_than(1.megabyte)
    end
    it do
      is_expected
        .to validate_uniqueness_of(:version_id)
        .scoped_to(%i[external_id provider_id])
        .with_message('with external ID and provider already exist')
    end
  end

  describe 'read-only instance' do
    context 'on create' do
      it { expect { thumbnail.save }.not_to raise_error }
    end

    context 'on update' do
      let(:thumbnail) { create :file_resource_thumbnail }
      it do
        expect { thumbnail.save }.to raise_error ActiveRecord::ReadOnlyRecord
      end
    end

    context 'on destroy' do
      let(:thumbnail) { create :file_resource_thumbnail }
      it { expect { thumbnail.destroy }.not_to raise_error }
    end
  end

  describe '.attributes_from_file_resource(file_resource)' do
    subject     { described_class.attributes_from_file_resource(file) }
    let(:file)  { instance_double FileResource }

    before do
      allow(file).to receive(:provider_id).and_return 'provider-id'
      allow(file).to receive(:external_id).and_return 'external-id'
      allow(file).to receive(:thumbnail_version_id).and_return 'version-id'
    end

    it do
      is_expected.to eq(
        provider_id: 'provider-id',
        external_id: 'external-id',
        version_id: 'version-id'
      )
    end
  end

  describe '.find_or_initialize_by_file_resource(file_resource)' do
    subject { described_class.find_or_initialize_by_file_resource('file') }

    before do
      allow(FileResource::Thumbnail)
        .to receive(:attributes_from_file_resource)
        .with('file').and_return 'attributes'
    end

    it 'calls #find_or_initialize_by with attributes' do
      expect(FileResource::Thumbnail)
        .to receive(:find_or_initialize_by).with('attributes')
      subject
    end
  end

  describe '.preload_for(objects)' do
    let(:file1)     { build_stubbed :file_resource, thumbnail_id: 1 }
    let(:file2)     { build_stubbed :file_resource, thumbnail_id: 2 }
    let(:file3)     { build_stubbed :file_resource, thumbnail_id: 1 }
    let(:file4)     { build_stubbed :file_resource, thumbnail_id: nil }
    let(:thumbnail1) { instance_double FileResource::Thumbnail }
    let(:thumbnail2) { instance_double FileResource::Thumbnail }

    before do
      allow(FileResource::Thumbnail)
        .to receive(:where)
        .with(id: [1, 2])
        .and_return [thumbnail1, thumbnail2]

      allow(thumbnail1).to receive(:id).and_return 1
      allow(thumbnail2).to receive(:id).and_return 2
    end

    it 'sets thumbnail on files' do
      FileResource::Thumbnail.preload_for([file1, file2, file3, file4])

      expect(file1.thumbnail).to eq thumbnail1
      expect(file2.thumbnail).to eq thumbnail2
      expect(file3.thumbnail).to eq thumbnail1
      expect(file4.thumbnail).to be nil
    end
  end

  describe '#file_resource=(file_resource)' do
    subject(:set_file_resource) { thumbnail.file_resource = 'file' }

    before do
      allow(FileResource::Thumbnail)
        .to receive(:attributes_from_file_resource)
        .with('file').and_return 'attributes'
    end

    it 'calls #assign_attributes with attributes' do
      expect(thumbnail).to receive(:assign_attributes).with('attributes')
      set_file_resource
    end
  end

  describe '#raw_image=(raw_image)' do
    subject(:raw_image) { thumbnail.raw_image = raw }
    let(:raw)           { proc { 'RAW-IMAGE'.downcase } }

    before do
      allow(StringIO)
        .to receive(:new).with('raw-image').and_return 'stringio-image'
    end

    it 'sets image' do
      expect(thumbnail).to receive(:image=).with('stringio-image')
      raw_image
    end
  end
end
