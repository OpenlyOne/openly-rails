# frozen_string_literal: true

RSpec.shared_examples 'using repository locking' do
  let(:locker) { repository }

  it 'uses locking' do
    expect(locker).to receive(:lock).once
    method
  end
end

RSpec.shared_examples 'not using repository locking' do
  it 'does not use locking' do
    expect(VersionControl::Repository).not_to receive(:lock)
    method
  end
end
