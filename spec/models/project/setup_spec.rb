# frozen_string_literal: true

RSpec.describe Project::Setup, type: :model do
  subject(:setup) { build_stubbed :project_setup }

  describe 'associations' do
    it { is_expected.to belong_to(:project) }
  end

  describe 'validations' do
    subject(:setup) { build :project_setup }

    it do
      is_expected
        .to validate_uniqueness_of(:project_id)
        .with_message('has already been set up')
    end
  end
end
