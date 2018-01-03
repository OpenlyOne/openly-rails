# frozen_string_literal: true

require 'models/shared_examples/caching_method_call.rb'
require 'models/shared_examples/version_control/repository_locking.rb'

RSpec.shared_examples 'being a staged file' do |skip_methods = []|
  describe 'class' do
    it  { is_expected.to be_an_instance_of described_class }
    it  { is_expected.to be_kind_of VersionControl::Files::Staged }
  end

  describe 'delegations' do
    it 'delegates lock to file_collection' do
      subject
      expect(subject.file_collection).to receive :lock
      subject.lock {}
    end
  end

  unless skip_methods.include?(:'.create')
    describe '.create(file_collection, params)' do
      subject(:method) do
        described_class.create(file_collection, params)
      end
      let(:root)            { create :file, :root, id: 'root' }
      let(:file_collection) { root.file_collection }
      let(:repository)      { file_collection.repository }
      let(:mime_type)       { 'application/vnd.google-apps.document' }
      let(:parent_id)       { root.id }
      let(:params) do
        {
          id: 'abc',
          name: 'my file',
          mime_type: mime_type,
          parent_id: parent_id,
          version: 5,
          modified_time: Time.zone.now
        }
      end

      it_should_behave_like 'using repository locking' do
        let(:locker) { file_collection }
      end

      it { is_expected.to be_a VersionControl::File }

      it 'writes metadata to root/abc' do
        method
        path = File.expand_path("#{root.id}/#{params[:id]}", repository.workdir)
        metadata = YAML.load_file(path).symbolize_keys
        expect(metadata)
          .to match params.slice(:name, :mime_type, :version, :modified_time)
      end

      context 'when file with ID already exists' do
        before { described_class.create(file_collection, params) }

        it 'raises ActiveRecord::RecordInvalid' do
          expect { method }.to raise_error ActiveRecord::RecordInvalid
        end
      end

      context 'when parent_id does not exist' do
        let(:parent_id) { 'non_existent' }
        let(:workdir)   { repository.workdir }

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

  unless skip_methods.include?(:ancestors)
    describe '#ancestors' do
      subject(:method)  { file.ancestors }
      let(:parent)      { create :file, :folder, parent: parent_of_parent }
      let(:parent_of_parent)  { create :file, :folder, parent: root }
      let(:root)              { create :file, :root, repository: repository }
      let(:repository)        { file.file_collection.repository }
      before { file.instance_variable_set :@parent_id, parent.id }

      it_should_behave_like 'using repository locking' do
        let(:locker) { file }
      end

      it_behaves_like 'caching method call', :ancestors do
        subject { file }
      end

      it 'returns [parent, parent_of_parent, root]' do
        expect(method.map(&:id)).to eq [parent.id, parent_of_parent.id, root.id]
      end

      it 'returns an array of staged files' do
        method.each do |ancestor|
          expect(ancestor).to be_a VersionControl::Files::Staged
        end
      end

      context 'when parent of file does not exist' do
        before  { file.instance_variable_set :@parent_id, 'blablablub' }
        it      { is_expected.to eq nil }
      end
    end
  end

  unless skip_methods.include?(:path)
    describe '#path' do
      subject(:method)  { file.path }
      let(:repository)  { file.file_collection.repository }

      it_should_behave_like 'using repository locking' do
        let(:locker) { file }
      end

      context 'when parent file exists' do
        let!(:root) { create :file, :root, repository: repository }
        before      { file.instance_variable_set :@parent_id, root.id }
        it { is_expected.to eq "#{repository.workdir}/#{root.id}/#{file.id}" }

        it_behaves_like 'caching method call', :path do
          subject { file }
        end
      end

      context 'when parent id does not exist in working directory' do
        before  { file.instance_variable_set :@parent_id, 'notfound' }
        it      { is_expected.to eq nil }
      end

      context 'when parent id is nil' do
        before  { file.instance_variable_set :@parent_id, nil }
        it      { is_expected.to eq nil }
      end
    end
  end

  unless skip_methods.include?(:update)
    describe '#update(params)' do
      subject(:method)  { file.update(params) }
      let(:repository)  { file.file_collection.repository }
      let(:root)        { create :file, :root, repository: repository }
      let(:parent_id)   { file.parent_id }
      let(:version)     { file.version + 1 }
      let(:params) do
        {
          name: 'my file',
          mime_type: file.mime_type,
          parent_id: parent_id,
          version: version,
          modified_time: Time.zone.now
        }
      end
      before { file.instance_variable_set :@parent_id, root.id }
      before { file.send :create }

      it_should_behave_like 'using repository locking' do
        let(:locker) { file }
      end

      it { is_expected.to be true }

      it 'changes attributes on file instance' do
        method
        expect(file).to have_attributes params
      end

      it 'persists new attributes to repository' do
        method
        persisted_file = repository.stage.files.find(file.id)
        expect(persisted_file).to have_attributes params
      end

      context 'params[:version] is not greater than existing version' do
        let(:version) { file.version }

        it { is_expected.to be false }

        it 'does not change attributes on file instance' do
          expect { method }.not_to change(file, :name)
        end

        it 'does not persist changes' do
          expect(file).not_to receive(:write_metadata)
          method
        end
      end

      context 'params[:parent_id] differs from existing parent_id' do
        let!(:new_parent) { create :file, :folder, parent: root }
        let(:parent_id)   { new_parent.id }

        it 'removes file at old path' do
          old_path = file.path
          method
          expect(::File).not_to exist(old_path)
        end

        it 'adds file at new path' do
          method
          persisted_file = repository.stage.files.find file.id
          expect(persisted_file.parent_id).to eq parent_id
        end

        context 'when file is not persisted' do
          before  { FileUtils.remove_dir(file.path) }
          it      { expect { method }.to raise_error(Errno::ENOENT) }
        end
      end

      context 'parent_id is nil' do
        let(:parent_id) { nil }

        it 'deletes the file' do
          method
          expect { repository.stage.files.find(file.id) }
            .to raise_error(ActiveRecord::RecordNotFound)
        end

        context 'when file is not persisted' do
          before  { FileUtils.remove_dir(file.path) }
          it      { expect { method }.to raise_error(Errno::ENOENT) }
        end
      end

      context 'parent_id does not exist in repository' do
        let(:parent_id) { 'does-not-exist-here' }

        it 'deletes the file' do
          method
          expect { repository.stage.files.find(file.id) }
            .to raise_error(ActiveRecord::RecordNotFound)
        end
      end
    end
  end

  unless skip_methods.include?(:'#create')
    describe '#create' do
      subject(:method)  { file.send :create }
      let(:repository)  { file.file_collection.repository }
      let(:path)        { ::File.expand_path(file.id, repository.workdir) }
      before { allow(file).to receive(:metadata_path).and_return(path) }

      it_should_behave_like 'using repository locking' do
        let(:locker) { file }
      end

      it 'writes metadata to metadata_path' do
        method
        path = ::File.expand_path(file.id, repository.workdir)
        metadata = YAML.load_file(path).symbolize_keys
        expect(metadata).to match file.send(:metadata)
      end
    end
  end

  unless skip_methods.include?(:metadata_path)
    describe '#metadata_path' do
      subject(:method) { file.send(:metadata_path) }

      context 'when path is abc/def/ghi' do
        before  { allow(file).to receive(:path).and_return('abc/def/ghi') }
        it      { is_expected.to eq 'abc/def/ghi' }
      end

      context 'when path is 123z54yBB' do
        before  { allow(file).to receive(:path).and_return('123z54yBB') }
        it      { is_expected.to eq '123z54yBB' }
      end

      context 'when path is nil' do
        before  { allow(file).to receive(:path).and_return(nil) }
        it      { is_expected.to eq nil }
      end
    end
  end

  unless skip_methods.include?(:move_to)
    describe '#move_to(new_parent_id)' do
      subject(:method)      { file.send :move_to, new_parent_id }
      let(:repository)      { file.file_collection.repository }
      let(:root)            { create :file, :root, repository: repository }
      let(:new_parent)      { create :file, :folder, parent: root }
      let(:new_parent_id)   { new_parent.id }
      let(:current_parent)  { root }
      before { file.instance_variable_set :@parent_id, current_parent.id }
      before { file.send :create }

      it_should_behave_like 'using repository locking' do
        let(:locker) { file }
      end

      it 'sets file path to root.id/new_parent.id/id' do
        method
        expect(file.path)
          .to eq "#{repository.workdir}/#{root.id}/#{new_parent.id}/#{file.id}"
      end

      it 'sets parent to new_parent.id' do
        method
        expect(file.parent_id).to eq new_parent_id
      end

      it 'removes file at old path' do
        old_path = file.path
        method
        expect(::File).not_to exist(old_path)
      end

      it 'adds file at new path' do
        method
        expect(::File).to exist(file.path)
      end

      it 'leaves file unchanged' do
        expect { method }.not_to(change { ::File.size(file.path) })
      end

      context 'when new_parent_id is equal to existing parent_id' do
        let(:new_parent_id) { file.parent_id }

        it 'does not rename the file' do
          expect(::File).not_to receive(:rename)
          method
        end

        it 'does not destroy the file' do
          old_path = file.path
          method
          expect(::File).to exist(old_path)
        end
      end

      context 'new_parent_id is nil' do
        let(:new_parent_id) { nil }

        it 'sets parent_id to nil' do
          method
          expect(file.parent_id).to eq nil
        end

        it 'deletes the file' do
          method
          expect { repository.stage.files.find(file.id) }
            .to raise_error(ActiveRecord::RecordNotFound)
        end
      end

      context 'new_parent_id is non-existent in repository' do
        let(:new_parent_id) { 'not-existing-here' }

        it 'sets parent to new parent id' do
          method
          expect(file.parent_id).to eq new_parent_id
        end

        it 'sets path to nil' do
          method
          expect(file.path).to eq nil
        end

        it 'deletes the file' do
          method
          expect { repository.stage.files.find(file.id) }
            .to raise_error(ActiveRecord::RecordNotFound)
        end
      end
    end
  end

  unless skip_methods.include?(:validate_for_creation!)
    describe '#validate_for_creation!' do
      subject(:method)  { file.send :validate_for_creation! }
      before            { allow(file).to receive(:path).and_return 'some-path' }

      it 'does not raise error' do
        expect { method }.not_to raise_error
      end

      it_should_behave_like 'using repository locking' do
        let(:locker) { file }
      end

      context 'when path is nil' do
        before { allow(file).to receive(:path).and_return(nil) }

        it 'raises ActiveRecord::RecordInvalid' do
          expect { method }.to raise_error ActiveRecord::RecordInvalid
        end
      end

      context 'when file with ID already exists' do
        let(:file_collection) { file.file_collection }
        before do
          FileUtils.touch(
            ::File.expand_path(file.id, file_collection.workdir)
          )
        end

        it 'raises ActiveRecord::RecordInvalid' do
          expect { method }.to raise_error ActiveRecord::RecordInvalid
        end
      end
    end
  end

  unless skip_methods.include?(:write_metadata)
    describe '#write_metadata' do
      subject(:method)  { file.send :write_metadata }
      let(:repository)  { file.file_collection.repository }
      let(:path)        { ::File.expand_path(file.id, repository.workdir) }
      before { allow(file).to receive(:metadata_path).and_return(path) }

      it_should_behave_like 'using repository locking' do
        let(:locker) { file }
      end

      it 'writes metadata to metadata_path' do
        method
        path = ::File.expand_path(file.id, repository.workdir)
        metadata = YAML.load_file(path).symbolize_keys
        expect(metadata).to match file.send(:metadata)
      end

      it 'writes metadata in a YAML.safe_load compatible format' do
        method
        path = ::File.expand_path(file.id, repository.workdir)
        metadata = File.read(path)
        expect do
          YAML.safe_load(metadata, Settings.whitelisted_yaml_classes)
        end.not_to raise_error
      end
    end
  end
end
