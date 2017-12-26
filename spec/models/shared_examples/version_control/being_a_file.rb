# frozen_string_literal: true

RSpec.shared_examples 'being a file' do
  describe 'attributes' do
    it { should respond_to(:file_collection) }
    it { should respond_to(:id) }
    it { should respond_to(:name) }
    it { should respond_to(:parent_id) }
    it { should respond_to(:mime_type) }
    it { should respond_to(:version) }
    it { should respond_to(:modified_time) }
  end

  describe 'delegations' do
    methods = %i[lock repository]

    methods.each do |method|
      it "delegates #{method}" do
        expect_any_instance_of(VersionControl::FileCollection).to receive method
        subject.send method
      end
    end
  end

  describe '#directory?' do
    before do
      allow(VersionControl::File)
        .to receive(:directory_type?)
        .with(subject.mime_type)
        .and_return(mime_type_is_directory)
    end

    context 'when .directory_type?(mime_type) is true' do
      let(:mime_type_is_directory) { true }
      it { is_expected.to be_directory }
    end

    context 'when .directory_type?(mime_type) is false' do
      let(:mime_type_is_directory) { false }
      it { is_expected.not_to be_directory }
    end
  end
end
