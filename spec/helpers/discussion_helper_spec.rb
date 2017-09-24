# frozen_string_literal: true

RSpec.describe DiscussionHelper, type: :helper do
  describe '#action_verb_for_initiated_by(discussion)' do
    subject(:method) { action_verb_for_initiated_by discussion }

    context 'when discussion is Discussions::Suggestion' do
      let(:discussion) { build :discussions_suggestion }
      it { is_expected.to eq 'suggested by' }
    end

    context 'when discussion is Discussions::Issue' do
      let(:discussion) { build :discussions_issue }
      it { is_expected.to eq 'raised by' }
    end

    context 'when discussion is Discussions::Question' do
      let(:discussion) { build :discussions_question }
      it { is_expected.to eq 'asked by' }
    end

    context 'when discussion is something else' do
      let(:discussion) { nil }
      it { is_expected.to eq 'initiated by' }
    end
  end
end
