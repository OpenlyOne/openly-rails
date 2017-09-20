# frozen_string_literal: true

RSpec.shared_examples 'being a discussion' do |discussion_type|
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
end
