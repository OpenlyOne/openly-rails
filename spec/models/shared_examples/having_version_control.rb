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

    context 'on update' do
      subject(:method)            { object.update updated_at: Time.now + 1.day }
      before                      { object.save }
      let(:repository_file_path)  { object.send(:repository_file_path) }
      let(:new_repository_file_path) do
        Rails.root.join(repository_file_path, '..', 'new-path').cleanpath.to_s
      end
      before do
        allow(object)
          .to receive(:repository_file_path)
          .and_return repository_file_path, new_repository_file_path
      end

      it { is_expected.to be_truthy }

      it 'moves the repository to the new path' do
        method
        expect(Rails.root.join(object.repository.workdir).cleanpath.to_s)
          .to eq new_repository_file_path
      end

      context 'when an error occurs' do
        before do
          allow_any_instance_of(VersionControl::Repository)
            .to receive(:rename)
            .and_raise 'error'
        end
        it { is_expected.to be_falsey }
        it 'does not save the object to the database' do
          expect { method }.not_to(change { object.reload.updated_at })
        end
      end

      context 'when update does not change output of #repository_file_path' do
        before do
          allow(object).to receive(:repository_file_path).and_call_original
        end
        it { is_expected.to be_truthy }
        it 'does not rename the repository' do
          expect { method }.not_to(change { object.repository.path })
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

  describe '#repository' do
    subject(:method) { object.repository }
    before do
      object.save
      # clear repository variable
      object.instance_variable_set :@repository, nil
    end

    context 'when repository exists' do
      before do
        VersionControl::Repository.create object.send(:repository_file_path)
      end
      it { is_expected.to be_a VersionControl::Repository }
    end

    context 'when repository does not exist' do
      before  { FileUtils.rm_rf object.send(:repository_file_path) }
      it      { is_expected.to be nil }
    end
  end
end
