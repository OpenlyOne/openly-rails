# frozen_string_literal: true

RSpec.shared_examples 'having version control' do
  describe 'callbacks' do
    context 'after create' do
      it { expect(object.save).to be_truthy }

      it 'calls create on VersionControl::Repository' do
        expect(VersionControl::Repository).to receive(:create)
        object.save
      end

      it 'creates a bare repository' do
        object.save
        expect(object.repository).to be_bare
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
  end

  describe '#repository' do
    subject(:method) { object.repository }

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
