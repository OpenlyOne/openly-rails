# frozen_string_literal: true

RSpec.describe Contribution, type: :model do
  subject(:contribution) { build_stubbed :contribution }

  it 'has a valid factory' do
    is_expected.to be_valid
  end

  describe 'associations' do
    it { is_expected.to belong_to(:project).dependent(false) }
    it do
      is_expected
        .to belong_to(:creator).class_name('Profiles::User').dependent(false)
    end
    it do
      is_expected
        .to belong_to(:branch).class_name('VCS::Branch').dependent(:destroy)
    end
  end

  describe 'delegations' do
    it do
      is_expected.to delegate_method(:branches).to(:project).with_prefix
      is_expected.to delegate_method(:master_branch).to(:project).with_prefix
      is_expected.to delegate_method(:revisions).to(:project).with_prefix
      is_expected.to delegate_method(:files).to(:branch)
    end
  end

  describe 'validations' do
    it do
      is_expected.to validate_presence_of(:project).with_message('must exist')
    end
    it do
      is_expected.to validate_presence_of(:creator).with_message('must exist')
    end
    it do
      is_expected.to validate_presence_of(:branch).with_message('must exist')
    end
    it { is_expected.to validate_presence_of(:title) }
    it { is_expected.to validate_presence_of(:description) }

    context 'on setup' do
      it { is_expected.to validate_absence_of(:branch).on(:setup) }
      it { is_expected.to validate_presence_of(:title).on(:setup) }
      it { is_expected.to validate_presence_of(:description).on(:setup) }
    end
  end

  describe '#setup' do
    subject(:setup) { contribution.setup('attrs') }

    let(:is_valid) { true }

    before do
      allow(contribution).to receive(:assign_attributes)
      allow(contribution).to receive(:valid?).and_return is_valid
      allow(contribution).to receive(:fork_master_branch)
      allow(contribution).to receive(:grant_creator_write_access_to_branch)
      allow(contribution).to receive(:save).and_return 'result-of-save'

      setup
    end

    it do
      expect(contribution).to have_received(:assign_attributes).with('attrs')
    end
    it { expect(contribution).to have_received(:valid?).with(:setup) }
    it { expect(contribution).to have_received(:fork_master_branch) }
    it do
      expect(contribution)
        .to have_received(:grant_creator_write_access_to_branch)
    end
    it { expect(contribution).to have_received(:save) }

    it 'returns the result of #save' do
      is_expected.to eq 'result-of-save'
    end

    context 'when it is not valid for setup' do
      let(:is_valid) { false }

      it { is_expected.to eq false }
      it do
        expect(contribution).not_to have_received(:fork_master_branch)
        expect(contribution)
          .not_to have_received(:grant_creator_write_access_to_branch)
      end
    end

    context 'when called without attributes' do
      subject(:setup) { contribution.setup }

      it { expect(contribution).to have_received(:assign_attributes).with({}) }
    end
  end
end
