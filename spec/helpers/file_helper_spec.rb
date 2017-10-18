# frozen_string_literal: true

RSpec.describe FileHelper, type: :helper do
  describe '#authorized_actions_for_project_file' do
    subject(:method)  { authorized_actions_for_project_file file, project }
    let(:project)     { build_stubbed :project }
    let(:file) do
      build :vc_file, collection: project.files, persisted: true
    end
    before do
      without_partial_double_verification do
        allow(self).to receive(:can?).and_return false
      end
    end

    it { is_expected.to be_none }

    context 'when user can edit file' do
      let(:link) do
        edit_profile_project_file_path project.owner, project, file
      end
      before do
        without_partial_double_verification do
          allow(self).to receive(:can?).with(:edit_content, file, project)
                                       .and_return true
        end
      end
      it { is_expected.to match [name: :edit, link: link, icon: anything] }
    end

    context 'when user can rename file' do
      let(:link) do
        rename_profile_project_file_path project.owner, project, file
      end
      before do
        without_partial_double_verification do
          allow(self).to receive(:can?).with(:edit_name, file, project)
                                       .and_return true
        end
      end
      it { is_expected.to match [name: :rename, link: link, icon: anything] }
    end

    context 'when user can delete file' do
      let(:link) do
        delete_profile_project_file_path project.owner, project, file
      end
      before do
        without_partial_double_verification do
          allow(self).to receive(:can?).with(:delete, file, project)
                                       .and_return true
        end
      end
      it { is_expected.to match [name: :delete, link: link, icon: anything] }
    end
  end
end
