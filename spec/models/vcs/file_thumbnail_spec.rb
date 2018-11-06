# frozen_string_literal: true

RSpec.describe VCS::FileThumbnail, type: :model do
  subject(:thumbnail) { build :vcs_file_thumbnail }

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
        .scoped_to(:external_id)
        .with_message('with external ID already exists')
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

  describe '.attributes_from_staged_file(file_resource)' do
    subject     { described_class.attributes_from_staged_file(file) }
    let(:file)  { instance_double VCS::StagedFile }

    before do
      allow(file).to receive(:external_id).and_return 'external-id'
      allow(file).to receive(:thumbnail_version_id).and_return 'version-id'
    end

    it do
      is_expected.to eq(external_id: 'external-id', version_id: 'version-id')
    end
  end

  describe '.find_or_initialize_by_staged_file(staged_file)' do
    subject { described_class.find_or_initialize_by_staged_file('file') }

    before do
      allow(VCS::FileThumbnail)
        .to receive(:attributes_from_staged_file)
        .with('file').and_return 'attributes'
    end

    it 'calls #find_or_initialize_by with attributes' do
      expect(VCS::FileThumbnail)
        .to receive(:find_or_initialize_by).with('attributes')
      subject
    end
  end

  describe '.preload_for(objects)' do
    let(:file1)     { build_stubbed :vcs_staged_file, thumbnail_id: 1 }
    let(:file2)     { build_stubbed :vcs_staged_file, thumbnail_id: 2 }
    let(:file3)     { build_stubbed :vcs_staged_file, thumbnail_id: 1 }
    let(:file4)     { build_stubbed :vcs_staged_file, thumbnail_id: nil }
    let(:thumbnail1) { instance_double VCS::FileThumbnail }
    let(:thumbnail2) { instance_double VCS::FileThumbnail }

    before do
      allow(VCS::FileThumbnail)
        .to receive(:where)
        .with(id: [1, 2])
        .and_return [thumbnail1, thumbnail2]

      allow(thumbnail1).to receive(:id).and_return 1
      allow(thumbnail2).to receive(:id).and_return 2
    end

    it 'sets thumbnail on files' do
      VCS::FileThumbnail.preload_for([file1, file2, file3, file4])

      expect(file1.thumbnail).to eq thumbnail1
      expect(file2.thumbnail).to eq thumbnail2
      expect(file3.thumbnail).to eq thumbnail1
      expect(file4.thumbnail).to be nil
    end
  end

  describe '#staged_file=(staged_file)' do
    subject(:set_staged_file) { thumbnail.staged_file = 'file' }

    before do
      allow(VCS::FileThumbnail)
        .to receive(:attributes_from_staged_file)
        .with('file').and_return 'attributes'
    end

    it 'calls #assign_attributes with attributes' do
      expect(thumbnail).to receive(:assign_attributes).with('attributes')
      set_staged_file
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
