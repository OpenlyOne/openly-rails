# frozen_string_literal: true

RSpec.describe Project, type: :model do
  subject(:project) { create :project }

  describe 'non_root_file_resources_in_stage#with_current_snapshot' do
    subject(:method) do
      project.non_root_file_resources_in_stage.with_current_snapshot
    end
    let(:file_resources_with_current_snapshot) { create_list :file_resource, 5 }
    let(:file_resources_without_current_snapshot) do
      create_list :file_resource, 5, :deleted
    end

    before do
      project.file_resources_in_stage << (
        file_resources_with_current_snapshot +
        file_resources_without_current_snapshot
      )
    end

    it 'returns file resources where current_snapshot is present' do
      expect(method.map(&:id))
        .to eq file_resources_with_current_snapshot.map(&:id)
    end

    it 'does not return file resources where current_snapshot = nil' do
      intersection_of_ids =
        method.map(&:id) & file_resources_without_current_snapshot.map(&:id)
      expect(intersection_of_ids).not_to be_any
    end
  end

  describe 'scope: :where_profile_is_owner_or_collaborator(profile)' do
    subject(:method) { Project.where_profile_is_owner_or_collaborator(profile) }
    let(:profile)         { create :user }
    let!(:owned_projects) { create_list :project, 3, owner: profile }
    let!(:collaborations) { create_list :project, 3 }
    let!(:other_projects) { create_list :project, 3 }

    before do
      # add profile as a collaborator
      collaborations.each do |project|
        project.collaborators << profile
      end
    end

    it 'returns projects owned by profile' do
      expect(method.map(&:id)).to include(*owned_projects.map(&:id))
    end

    it 'returns projects in which profile is a collaborator' do
      expect(method.map(&:id)).to include(*collaborations.map(&:id))
    end

    it 'does not return other projects' do
      expect(method.map(&:id)).not_to include(*other_projects.map(&:id))
    end

    context 'when owned project has collaborators' do
      let(:collaborators) { create_list :user, 3 }

      before do
        owned_projects.each do |project|
          project.collaborators << collaborators
        end
      end

      it 'returns only distinct projects' do
        expect(method.map(&:id).uniq).to eq method.map(&:id)
      end
    end
  end
end
