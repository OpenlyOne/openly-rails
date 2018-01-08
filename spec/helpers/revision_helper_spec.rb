# frozen_string_literal: true

RSpec.describe FileHelper, type: :helper do
  describe '#format_revision_errors!(revision, link_to_start_over)' do
    subject(:method) do
      helper.format_revision_errors! revision, link_to_start_over
    end
    let(:revision)            { repository.build_revision }
    let(:repository)          { build :repository }
    let(:link_to_start_over)  { '' }

    context 'when revision errors include :last_revision_id' do
      before { revision.errors[:last_revision_id] << 'error' }

      it 'removes all :last_revision_id errors' do
        method
        expect(revision.errors.include?(:last_revision_id)).to be false
      end

      it 'adds explanation that another commit has occured' do
        method
        expect(revision.errors.full_messages.join).to include(
          'Someone else has committed changes to this project since you ' \
          'started reviewing changes.'
        )
      end
    end

    context 'when revision errors do not include :last_revision_id' do
      it 'changes nothing' do
        expect { method }.not_to(change { revision.errors.messages })
      end
    end
  end
end
