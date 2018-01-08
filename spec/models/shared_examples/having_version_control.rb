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

  describe '.find_each_repository' do
    let(:dir_path)  { described_class.repository_folder_path }
    let!(:repo1)    { create :repository, dir: dir_path }
    let!(:repo2)    { create :repository, dir: dir_path }
    let!(:repo3)    { create :repository, dir: dir_path }
    let!(:repo4)    { create :repository, dir: dir_path }
    let!(:repo5)    { create :repository, dir: dir_path }

    it 'yields for each repository that exists' do
      expect { |b| described_class.find_each_repository(&b) }
        .to yield_control.exactly(5).times
    end

    it 'yields the repository' do
      expect(STDOUT).to receive(:puts).with repo1.path
      expect(STDOUT).to receive(:puts).with repo2.path
      expect(STDOUT).to receive(:puts).with repo3.path
      expect(STDOUT).to receive(:puts).with repo4.path
      expect(STDOUT).to receive(:puts).with repo5.path
      described_class.find_each_repository do |repository|
        puts repository.path
      end
    end

    context 'when :lock is passed' do
      it 'locks each repository before yielding' do
        expect(VersionControl::Repository).to receive(:lock).with repo1.workdir
        expect(VersionControl::Repository).to receive(:lock).with repo2.workdir
        expect(VersionControl::Repository).to receive(:lock).with repo3.workdir
        expect(VersionControl::Repository).to receive(:lock).with repo4.workdir
        expect(VersionControl::Repository).to receive(:lock).with repo5.workdir
        described_class.find_each_repository(:lock) { |_| }
      end
    end

    context 'when some other value is passed' do
      it 'does not lock repository before yielding' do
        expect(VersionControl::Repository).not_to receive(:lock)
        described_class.find_each_repository(:false_value) { |_| }
      end
    end

    context 'when nothing is passed' do
      it 'does not lock repository before yielding' do
        expect(VersionControl::Repository).not_to receive(:lock)
        described_class.find_each_repository { |_| }
      end
    end

    context 'when repository_folder_path does not exist' do
      before { FileUtils.remove_entry described_class.repository_folder_path }

      it 'does not raise an error' do
        expect { described_class.find_each_repository {} }.not_to raise_error
      end

      it 'does not yield' do
        expect { |b| described_class.find_each_repository(&b) }
          .not_to yield_control
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
