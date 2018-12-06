# frozen_string_literal: true

RSpec.describe VCS::Thumbnail, type: :model do
  subject(:thumbnail) { build :vcs_file_thumbnail }

  describe 'associations' do
    it { is_expected.to belong_to(:file) }
    it do
      is_expected
        .to have_many(:file_versions)
        .with_foreign_key(:thumbnail_id)
        .dependent(:nullify)
    end
    it do
      is_expected
        .to have_many(:files_in_branches)
        .class_name('FileInBranch')
        .with_foreign_key(:thumbnail_id)
        .dependent(:nullify)
    end
  end

  describe 'attachments' do
    it { is_expected.to have_attached_file(:image) }
  end

  describe 'validations' do
    it do
      is_expected
        .to validate_presence_of(:file).with_message('must exist')
    end
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
        .scoped_to(%i[file_id remote_file_id])
        .with_message('with remote ID already exists for this file record')
    end
  end

  describe 'read-only instance' do
    context 'on create' do
      it { expect { thumbnail.save }.not_to raise_error }
    end

    context 'on update' do
      let(:thumbnail) { create :vcs_file_thumbnail }
      it do
        expect { thumbnail.save }.to raise_error ActiveRecord::ReadOnlyRecord
      end
    end

    context 'on destroy' do
      let(:thumbnail) { create :vcs_file_thumbnail }
      it { expect { thumbnail.destroy }.not_to raise_error }
    end
  end

  describe '.attributes_from_file_in_branch(file_resource)' do
    subject     { described_class.attributes_from_file_in_branch(file) }
    let(:file)  { instance_double VCS::FileInBranch }

    before do
      allow(file).to receive(:file_id).and_return 'FRID'
      allow(file).to receive(:remote_file_id).and_return 'remote-id'
      allow(file).to receive(:thumbnail_version_id).and_return 'version-id'
    end

    it do
      is_expected.to eq(
        file_id: 'FRID',
        remote_file_id: 'remote-id',
        version_id: 'version-id'
      )
    end
  end

  describe '.find_or_initialize_by_file_in_branch(file_in_branch)' do
    subject { described_class.find_or_initialize_by_file_in_branch('file') }

    before do
      allow(VCS::Thumbnail)
        .to receive(:attributes_from_file_in_branch)
        .with('file').and_return 'attributes'
    end

    it 'calls #find_or_initialize_by with attributes' do
      expect(VCS::Thumbnail)
        .to receive(:find_or_initialize_by).with('attributes')
      subject
    end
  end

  describe '.preload_for(objects)' do
    let(:file1)     { build_stubbed :vcs_file_in_branch, thumbnail_id: 1 }
    let(:file2)     { build_stubbed :vcs_file_in_branch, thumbnail_id: 2 }
    let(:file3)     { build_stubbed :vcs_file_in_branch, thumbnail_id: 1 }
    let(:file4)     { build_stubbed :vcs_file_in_branch, thumbnail_id: nil }
    let(:thumbnail1) { instance_double VCS::Thumbnail }
    let(:thumbnail2) { instance_double VCS::Thumbnail }

    before do
      allow(VCS::Thumbnail)
        .to receive(:where)
        .with(id: [1, 2])
        .and_return [thumbnail1, thumbnail2]

      allow(thumbnail1).to receive(:id).and_return 1
      allow(thumbnail2).to receive(:id).and_return 2
    end

    it 'sets thumbnail on files' do
      VCS::Thumbnail.preload_for([file1, file2, file3, file4])

      expect(file1.thumbnail).to eq thumbnail1
      expect(file2.thumbnail).to eq thumbnail2
      expect(file3.thumbnail).to eq thumbnail1
      expect(file4.thumbnail).to be nil
    end
  end

  describe '#file_in_branch=(file_in_branch)' do
    subject(:set_file_in_branch) { thumbnail.file_in_branch = 'file' }

    before do
      allow(VCS::Thumbnail)
        .to receive(:attributes_from_file_in_branch)
        .with('file').and_return 'attributes'
    end

    it 'calls #assign_attributes with attributes' do
      expect(thumbnail).to receive(:assign_attributes).with('attributes')
      set_file_in_branch
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
