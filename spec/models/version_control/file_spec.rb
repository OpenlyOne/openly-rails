# frozen_string_literal: true

RSpec.describe VersionControl::File, type: :model do
  subject(:file) { build :vc_file }

  it 'has a valid factory' do
    expect { subject }.not_to raise_error
  end

  describe '#content' do
    subject(:method)  { file.content }
    let(:file)        { create :vc_file }
    it                { is_expected.to eq file.content }
  end
end
