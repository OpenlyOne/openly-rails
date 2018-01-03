# frozen_string_literal: true

RSpec.shared_examples 'having version control' do
  describe 'callbacks' do
    context 'after create' do
      it { expect(object.save).to be_truthy }

      it 'calls create on VersionControl::Repository' do
        expect(VersionControl::Repository).to receive(:create)
        object.save
      end

      it 'creates a non-bare repository' do
        object.save
        expect(object.repository).not_to be_bare
      end

      context 'when an error occurs' do
        before do
          allow(Rugged::Repository).to receive(:init_at).and_raise 'error'
        end
        it 'does not save the object to the database' do
          expect { object.save }.not_to change(object.class, :count)
        end
      end
    end

    context 'after destroy' do
      subject(:method)      { object.destroy }
      let(:repository_path) { object.send :repository_file_path }
      before                { object.save }

      it { is_expected.to be_truthy }

      it 'deletes the files at repository_file_path' do
        method
        expect(File).not_to exist repository_path
      end

      context 'when an error occurs' do
        before do
          allow(object)
            .to receive(:destroy_repository)
            .and_raise 'error'
        end
        it { is_expected.to be_falsey }
        it 'does not save the object to the database' do
          expect { method }.not_to change object.class, :count
        end
      end
    end
  end

  describe 'delegations' do
    before { object.save }

    it 'delegates stage to repository with prefix :repository' do
      expect_any_instance_of(VersionControl::Repository).to receive :stage
      subject.send :repository_stage
    end

    it 'delegates files to repository_stage' do
      expect_any_instance_of(VersionControl::Revisions::Staged)
        .to receive :files
      subject.send :files
    end

    it 'delegates revisions to repository' do
      expect_any_instance_of(VersionControl::Repository).to receive :revisions
      subject.send :revisions
    end

    context 'when repository is nil' do
      before { allow(object).to receive(:repository).and_return nil }

      it 'returns nil on calling #repository_stage' do
        expect(subject.send(:repository_stage)).to eq nil
      end

      it 'returns nil on calling #files' do
        expect(subject.send(:files)).to eq nil
      end

      it 'returns nil on calling #revisions' do
        expect(subject.send(:revisions)).to eq nil
      end
    end
  end

  describe '#reload' do
    subject(:method) { object.reload }
    before { object.save }

    it 'resets @repository' do
      object.repository
      expect { method }.to(
        change { object.instance_variable_get(:@repository) }.to(nil)
      )
    end

    it 'reloads the object from database' do
      expect(object.class).to receive(:find)
      subject
    end
  end

  describe '#repository' do
    subject(:method) { object.repository }
    before do
      object.save
      # clear repository variable
      object.instance_variable_set :@repository, nil
    end

    context 'when repository exists' do
      it { is_expected.to be_a VersionControl::Repository }
    end

    context 'when repository does not exist' do
      before  { FileUtils.rm_rf object.send(:repository_file_path) }
      it      { is_expected.to be nil }
    end

    context 'when repository_file_path is nil' do
      before  { allow(object).to receive(:repository_file_path).and_return nil }
      it      { is_expected.to be nil }
    end
  end
end
