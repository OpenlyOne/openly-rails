# frozen_string_literal: true

RSpec.describe CommittedFile, type: :model do
  subject(:file) { build_stubbed :committed_file }

  describe 'associations' do
    it do
      is_expected.to belong_to(:revision).autosave(false).dependent(false)
    end
    it do
      is_expected.to belong_to(:file_resource).autosave(false).dependent(false)
    end
    it do
      is_expected
        .to belong_to(:file_resource_snapshot)
        .class_name('FileResource::Snapshot')
        .dependent(false)
    end
  end

  describe 'validations' do
    subject(:file) { build :committed_file }

    it do
      is_expected
        .to validate_uniqueness_of(:file_resource_id)
        .scoped_to(:revision_id)
        .with_message('already exists in this revision')
    end
  end

  describe 'read-only instance' do
    subject(:file)  { build :committed_file }
    let(:create)    { file.save }
    let(:update)    { create && file.update(updated_at: Time.zone.now) }
    let(:destroy)   { create && file.destroy }

    before { allow(file).to receive(:revision_published?).and_return published }

    context 'when revision is not published' do
      let(:published) { false }

      it { expect { create }.not_to raise_error }
      it { expect { update }.not_to raise_error }
      it { expect { destroy }.not_to raise_error }
    end

    context 'when revision is published' do
      let(:published) { true }

      it { expect { create }.to raise_error ActiveRecord::ReadOnlyRecord }
      it { expect { update }.to raise_error ActiveRecord::ReadOnlyRecord }
      it { expect { destroy }.to raise_error ActiveRecord::ReadOnlyRecord }
    end
  end

  describe '.insert_from_select_query(columns, query)' do
    subject(:insert)  { described_class.insert_from_select_query(cols, query) }
    let(:cols)        { %i[col1 col2] }
    let(:query)       { instance_double ActiveRecord::Relation }

    before do
      allow(ActiveRecord::Base.connection)
        .to receive(:execute).and_call_original
      q = instance_double ActiveRecord::Relation
      allow(query)
        .to receive(:select)
        .with('NOW() AS created_at', 'NOW() AS updated_at')
        .and_return q
      allow(q).to receive(:to_sql).and_return 'select-query-to-sql'
    end

    it 'calls ActiveRecord::Base.connection#execute' do
      expect(ActiveRecord::Base.connection).to receive(:execute).with(
        "INSERT INTO committed_files (col1, col2, created_at, updated_at)\n" \
        'select-query-to-sql'
      ).and_return true
      insert
    end
  end
end
