# frozen_string_literal: true

require 'models/shared_examples/version_control/being_a_file.rb'
require 'models/shared_examples/version_control/being_a_staged_file.rb'
require 'models/shared_examples/version_control/being_a_staged_folder.rb'
require 'models/shared_examples/version_control/repository_locking.rb'

RSpec.describe VersionControl::Files::Staged::Root, type: :model do
  subject(:root) { build :file, :root }

  it_should_behave_like 'being a file' do
    let(:file) { root }
  end
  it_should_behave_like 'being a staged file',
                        %i[.create #create ancestors update metadata_path
                           move_to path validate_for_creation!] do
    let(:file) { root }
  end
  it_should_behave_like 'being a staged folder' do
    let(:folder) { root }
  end

  describe '.create(file_collection, params)' do
    subject(:method) do
      VersionControl::Files::Staged::Root.create(file_collection, params)
    end
    let(:file_collection) { repository.stage.files }
    let(:repository)      { build :repository }
    let(:params) do
      {
        id: 'abc',
        name: 'my file',
        mime_type: 'application/vnd.google-apps.folder',
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
      path = ::File.expand_path(params[:id], repository.workdir)
      expect(::File).to be_directory(path)
    end

    it 'writes metadata to abc/.self' do
      method
      path = ::File.expand_path("#{params[:id]}/.self", repository.workdir)
      metadata = YAML.load_file(path).symbolize_keys
      expect(metadata)
        .to match params.slice(:name, :mime_type, :version, :modified_time)
    end

    context 'when a root folder already exists' do
      before { create :file, :root, repository: repository }

      it 'raises ActiveRecord::RecordInvalid' do
        expect { method }.to raise_error ActiveRecord::RecordInvalid
      end
    end
  end

  describe '#ancestors' do
    subject(:method)  { root.ancestors }
    it                { is_expected.to eq [] }
  end

  describe '#parent_id' do
    subject(:method)  { root.parent_id }
    let(:root)        { build :file, :root, parent_id: 'blabla' }
    before            { allow(STDOUT).to receive(:puts) }
    it                { is_expected.to be nil }
    it 'prints a warning' do
      expect(STDOUT).to receive(:puts).with(
        'Warning: #parent_id called for VersionControl::Files::Staged::Root'
      )
      method
    end
  end

  describe '#path' do
    subject(:method)  { root.path }
    let(:workdir)     { root.file_collection.workdir }
    it                { is_expected.to eq "#{workdir}/#{root.id}" }
  end

  describe '#update(params)' do
    subject(:method)  { root.update(params) }
    let(:root)        { create :file, :root }
    let(:repository)  { root.file_collection.repository }
    let(:version)     { root.version + 1 }
    let(:params) do
      {
        name: 'my file',
        mime_type: root.mime_type,
        version: version,
        modified_time: Time.zone.now
      }
    end

    it_should_behave_like 'using repository locking' do
      let(:locker) { root }
    end

    it { is_expected.to be true }

    it 'changes attributes on file instance' do
      method
      expect(root).to have_attributes params
    end

    it 'persists new attributes to repository' do
      method
      persisted_file = repository.stage.files.find(root.id)
      expect(persisted_file).to have_attributes params
    end

    context 'params[:version] is not greater than existing version' do
      let(:version) { root.version }

      it { is_expected.to be false }

      it 'does not change attributes on file instance' do
        expect { method }.not_to change(root, :name)
      end

      it 'does not persist changes' do
        expect(root).not_to receive(:write_metadata)
        method
      end
    end

    context 'params[:parent_id] is set' do
      before { params[:parent_id] = 'super-cool-id' }

      it 'does not rename the file' do
        expect(::File).not_to receive(:rename)
        method
      end

      it 'does not destroy the file' do
        old_path = root.path
        method
        expect(::File).to exist(old_path)
      end
    end

    context 'when file is not persisted' do
      let(:root)  { build :file, :root }
      it          { expect { method }.to raise_error(Errno::ENOENT) }
    end
  end

  describe '#validate_for_creation!' do
    subject(:method)  { root.send :validate_for_creation! }
    let(:repository)  { root.file_collection.repository }

    it_should_behave_like 'using repository locking' do
      let(:locker) { root }
    end

    it 'does not raise error' do
      expect { method }.not_to raise_error
    end

    context 'when root folder exists' do
      before { FileUtils.touch("#{repository.workdir}/root") }
      it 'raises ActiveRecord::RecordInvalid' do
        expect { method }.to raise_error ActiveRecord::RecordInvalid
      end
    end
  end

  describe '#move_to' do
    subject(:method)  { root.send :move_to }
    it                { is_expected.to be nil }
  end
end
