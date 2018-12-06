# frozen_string_literal: true

RSpec.describe VCS::CommittedFile, type: :model do
  subject(:file) { build_stubbed :vcs_committed_file }

  describe 'associations' do
    it { is_expected.to belong_to(:commit).autosave(false).dependent(false) }
    it do
      is_expected.to belong_to(:version).autosave(false).dependent(false)
    end
  end

  describe 'scopes' do
    it 'has scope: where_version_changed_between_commits' do
      expect(described_class)
        .to respond_to(:where_version_changed_between_commits)
        .with(2).arguments
    end
  end

  describe 'validations' do
    subject(:file) { build :vcs_committed_file }

    it do
      is_expected
        .to validate_uniqueness_of(:version_id)
        .scoped_to(:commit_id)
        .with_message('file version already exists in this revision')
    end
  end

  describe 'read-only instance' do
    subject(:file)  { build :vcs_committed_file }
    let(:create)    { file.save }
    let(:update)    { create && file.update(updated_at: Time.zone.now) }
    let(:destroy)   { create && file.destroy }

    before { allow(file).to receive(:commit_published?).and_return published }

    context 'when commit is not published' do
      let(:published) { false }

      it { expect { create }.not_to raise_error }
      it { expect { update }.not_to raise_error }
      it { expect { destroy }.not_to raise_error }
    end

    context 'when commit is published' do
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
        'INSERT INTO vcs_committed_files (col1, col2, created_at, updated_at)' \
        "\n" \
        'select-query-to-sql'
      ).and_return true
      insert
    end
  end
end
