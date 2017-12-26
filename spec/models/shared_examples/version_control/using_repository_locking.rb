# frozen_string_literal: true

RSpec.shared_examples 'using repository locking' do
  let(:locker) { repository }

  it 'uses locking' do
    expect(locker).to receive(:lock).once
    method
  end
end
