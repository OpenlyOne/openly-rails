# frozen_string_literal: true

RSpec.describe VersionControl::File, type: :model do
  describe '.new(file_collection, params)' do
    subject(:method)  { VersionControl::File.new(collection, {}) }
    let(:collection)  { klass.new(r) }
    let(:r)           { class_double 'VersionControl::Repository' }

    context 'when collection is VersionControl::FileCollections::Staged' do
      let(:klass) { VersionControl::FileCollections::Staged }
      it { is_expected.to be_an_instance_of VersionControl::Files::Staged }
    end

    context 'when collection is none of the above' do
      let(:klass) { VersionControl::FileCollection }
      it 'raises an ActiveRecord::TypeConflictError' do
        expect { method }.to raise_error(
          ActiveRecord::TypeConflictError,
          "Type #{collection} is not supported."
        )
      end
    end
  end

  describe '.directory_type?(mime_type)' do
    subject(:method) { VersionControl::File.directory_type?(mime_type) }

    context 'when mime type is Google Drive folder' do
      let(:mime_type) { 'application/vnd.google-apps.folder' }
      it { is_expected.to be true }
    end

    context 'when mime type is Google Drive document' do
      let(:mime_type) { 'application/vnd.google-apps.document' }
      it { is_expected.to be false }
    end

    context 'when mime type is Google Drive spreadsheet' do
      let(:mime_type) { 'application/vnd.google-apps.spreadsheet' }
      it { is_expected.to be false }
    end
  end
end
