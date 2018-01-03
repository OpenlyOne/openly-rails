# frozen_string_literal: true

require 'models/shared_examples/version_control/being_a_file.rb'
require 'models/shared_examples/version_control/being_a_staged_file.rb'
require 'models/shared_examples/version_control/being_a_staged_folder.rb'
require 'models/shared_examples/version_control/repository_locking.rb'

RSpec.describe VersionControl::Files::Staged::Folder, type: :model do
  subject(:folder) { build :file, :folder }

  it_should_behave_like 'being a file' do
    let(:file) { folder }
  end
  it_should_behave_like 'being a staged file',
                        %i[.create #create metadata_path] do
    let(:file) { folder }
  end
  it_should_behave_like 'being a staged folder' do
    subject(:folder)  { build :file, :folder, parent: root }
    let(:root)        { create :file, :root }
  end

  describe '.create(file_collection, params)' do
    subject(:method) do
      VersionControl::Files::Staged::Folder.create(file_collection, params)
    end
    let(:root)            { create :file, :root }
    let(:file_collection) { root.file_collection }
    let(:repository)      { file_collection.repository }
    let(:parent_id)       { root.id }
    let(:params) do
      {
        id: 'abc',
        name: 'my file',
        mime_type: 'application/vnd.google-apps.folder',
        parent_id: parent_id,
        version: 5,
        modified_time: Time.zone.now
      }
    end

    it_should_behave_like 'using repository locking' do
      let(:locker) { file_collection }
    end

    it { is_expected.to be_a VersionControl::File }

    it 'creates a directory at abc' do
      method
      path = ::File.expand_path(params[:id], root.path)
      expect(::File).to be_directory(path)
    end

    it 'writes metadata to abc/.self' do
      method
      path = ::File.expand_path("#{params[:id]}/.self", root.path)
      metadata = YAML.load_file(path).symbolize_keys
      expect(metadata)
        .to match params.slice(:name, :mime_type, :version, :modified_time)
    end

    context 'when directory with same ID already exists' do
      before { create :file, :folder, id: params[:id], parent: root }

      it 'raises ActiveRecord::RecordInvalid' do
        expect { method }.to raise_error ActiveRecord::RecordInvalid
      end
    end

    context 'when parent_id does not exist' do
      let(:parent_id) { 'non_existent' }

      it 'raises ActiveRecord::RecordInvalid' do
        expect { method }.to raise_error ActiveRecord::RecordInvalid
      end
    end

    context 'when parent_id is nil' do
      let(:parent_id) { nil }

      it 'raises ActiveRecord::RecordInvalid' do
        expect { method }.to raise_error ActiveRecord::RecordInvalid
      end
    end
  end
end
