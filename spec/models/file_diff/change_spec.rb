# frozen_string_literal: true

RSpec.describe FileDiff::Change, type: :model do
  subject(:change)  { FileDiff::Change.new(diff: diff, type: :type) }
  let(:diff)        { instance_double FileDiff }

  describe 'delegations' do
    it { is_expected.to delegate_method(:ancestor_path).to(:diff) }
    it do
      is_expected.to delegate_method(:current_or_previous_snapshot).to(:diff)
    end
    it { is_expected.to delegate_method(:external_id).to(:diff) }
    it { is_expected.to delegate_method(:icon).to(:diff) }
    it { is_expected.to delegate_method(:name).to(:diff) }
    it { is_expected.to delegate_method(:symbolic_mime_type).to(:diff) }
  end
end
