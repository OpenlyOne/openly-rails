# frozen_string_literal: true

RSpec.shared_examples 'being a file collection' do
  describe 'attributes' do
    it { should respond_to(:revision) }
  end

  describe 'delegations' do
    it 'delegates repository to revision' do
      subject
      expect(subject.revision).to receive :repository
      subject.repository
    end
  end

  describe '.parent_id_from_relative_path(path)' do
    subject(:method) do
      VersionControl::FileCollection.parent_id_from_relative_path(path)
    end

    context 'when path is abc/def' do
      let(:path)  { 'abc/def' }
      it          { is_expected.to eq 'abc' }
    end

    context 'when path is abc/def/ghi' do
      let(:path)  { 'abc/def/ghi' }
      it          { is_expected.to eq 'def' }
    end

    context 'when path is in abc' do
      let(:path)  { 'abc' }
      it          { is_expected.to eq nil }
    end
  end
end
