# frozen_string_literal: true

RSpec.shared_examples 'vcs: having remote' do
  describe '#remote' do
    it 'sets @remote' do
      object.remote = 'some-value'
      expect(object.instance_variable_get(:@remote)).to eq 'some-value'
    end
  end

  describe '#remote' do
    subject(:remote) { object.remote }

    let(:remote_class) { object.send(:remote_class) }

    before do
      allow(object).to receive(:remote_file_id).and_return 'remote-id'
      allow(remote_class).to receive(:new).and_return 'new-instance'

      hook if defined?(hook)

      object.remote
    end

    it 'returns an instance of remote class' do
      expect(remote_class).to have_received(:new).with('remote-id')
    end

    it 'sets @remote to new instance' do
      expect(object.instance_variable_get(:@remote)).to eq 'new-instance'
    end

    context 'when @remote is already set' do
      let(:hook) { object.instance_variable_set(:@remote, 'existing-value') }

      it { is_expected.to eq 'existing-value' }
    end
  end

  describe '#reload' do
    before do
      allow(object).to receive(:reset_remote)
      allow(object.class).to receive(:find)
      object.reload
    end

    it { expect(object).to have_received(:reset_remote) }

    it 'reloads the object from database' do
      expect(object.class).to have_received(:find)
    end
  end

  describe '#reset_remote' do
    subject(:reset_remote) { object.send(:reset_remote) }

    before do
      object.instance_variable_set(:@remote, 'some-value')
    end

    it 'resets @remote to nil' do
      reset_remote
      expect(object.instance_variable_get(:@remote)).to eq nil
    end
  end

  describe '#remote_class' do
    subject { object.send(:remote_class) }

    it { is_expected.to eq Providers::GoogleDrive::FileSync }
  end
end
