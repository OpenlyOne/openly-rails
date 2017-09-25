# frozen_string_literal: true

RSpec.shared_examples 'being a discussion' do |discussion_type|
  describe 'has a project-scoped ID' do
    let(:project)           { subject.project }
    let(:subject_scoped_id) { subject.scoped_id }

    before { subject.save }

    context 'creating new discussions on the same project' do
      it 'has a scoped ID of 1' do
        expect(subject.scoped_id).to eq 1
      end

      it 'increments the scoped id by 1' do
        expect(create(:discussions_suggestion, project: project).scoped_id)
          .to eq 2
        expect(create(:discussions_issue, project: project).scoped_id).to eq 3
        expect(create(:discussions_question, project: project).scoped_id)
          .to eq 4
      end
    end

    context 'creating new discussions on a different project' do
      it 'has a scoped ID of 1' do
        expect(subject.scoped_id).to eq 1
      end

      it 'new discussions on different projects all have scoped ID of 1' do
        expect(create(:discussions_suggestion).scoped_id).to eq 1
        expect(create(:discussions_issue).scoped_id).to eq 1
        expect(create(:discussions_question).scoped_id).to eq 1
      end
    end
  end

  describe 'associations' do
    it { is_expected.to belong_to(:initiator) }
    it { is_expected.to belong_to(:project) }
  end

  describe 'validations' do
    it do
      is_expected.to validate_presence_of(:initiator).with_message 'must exist'
    end
    it do
      is_expected.to validate_presence_of(:project).with_message 'must exist'
    end
    it { is_expected.to validate_presence_of(:title) }
    it { is_expected.to validate_length_of(:title).is_at_most(100) }
    context ':type' do
      it "'#{discussion_type}' is valid" do
        subject.type = discussion_type
        expect(subject).to be_valid
      end
      invalid_types =
        %w[Discussions::Base Discussions::Suggestion Discussions::Issue
           Discussions::Question] - [discussion_type.to_s]
      invalid_types.each do |type|
        it "'#{type}' is invalid" do
          subject.type = type
          expect(subject).to be_invalid
        end
      end
    end
  end

  describe '#to_param' do
    before  { subject.save }
    it      { expect(subject.to_param).to eq 1 }
  end

  describe '#type_to_url_segment' do
    it { expect(subject.type_to_url_segment).to eq url_type }
  end
end
