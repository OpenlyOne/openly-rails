# frozen_string_literal: true

require 'models/shared_examples/version_control/being_a_file.rb'
require 'models/shared_examples/version_control/being_a_staged_file.rb'

RSpec.describe VersionControl::Files::Staged, type: :model do
  subject(:file) { build :file }

  it_should_behave_like 'being a file'
  it_should_behave_like 'being a staged file'

  describe '.new(file_collection, params)' do
    subject(:method)  { VersionControl::Files::Staged.new(collection, params) }
    let(:collection)  { class_double 'VersionControl::Revisions::Staged' }

    context 'default' do
      let(:params) { {} }
      it { is_expected.to be_an_instance_of VersionControl::Files::Staged }
    end

    context 'when params[:is_root] is true' do
      let(:params) { { is_root: true } }
      it do
        is_expected.to be_an_instance_of VersionControl::Files::Staged::Root
      end
    end

    context 'when params[:mime_type] is folder' do
      let(:params) { { mime_type: 'application/vnd.google-apps.folder' } }
      it do
        is_expected.to be_an_instance_of VersionControl::Files::Staged::Folder
      end
    end
  end
end
