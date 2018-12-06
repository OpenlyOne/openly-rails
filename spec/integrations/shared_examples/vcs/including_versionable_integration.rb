# frozen_string_literal: true

RSpec.shared_examples 'vcs: including versionable integration' do
  describe 'callbacks' do
    let(:creation)      { versionable.save }
    let(:from_database) { versionable.class.find(versionable.id) }

    describe 'creation' do
      it do
        expect { creation }.to change { VCS::Version.count }.by(1)
      end
    end

    describe 'update' do
      subject(:method)  { from_database.update(name: 'name', mime_type: 'doc') }
      before            { creation }
      it { expect { method }.to change { VCS::Version.count }.by(1) }
    end

    describe 'is_deleted = true' do
      subject(:method)    { from_database.update(is_deleted: true) }
      before              { creation }
      it { expect { method }.not_to(change { VCS::Version.count }) }
      it { expect { method }.not_to(change { VCS::FileInBranch.count }) }
    end

    describe 'when version already exists' do
      let!(:original_name) { versionable.name }
      let(:original_version_id) do
        versionable.file.versions.first.id
      end

      before do
        # create a version with original attributes
        versionable.save

        # create a version with new name
        versionable.update(name: 'new-name')

        # reset attributes to original ones
        versionable.name = original_name
      end

      it 'does not create a new version' do
        expect { versionable.save }
          .not_to change(VCS::Version, :count)
      end

      it 'sets current version ID to the existing version' do
        expect { versionable.save }
          .to change(versionable, :current_version_id)
          .to(original_version_id)
      end

      context 'when supplemental attributes change' do
        let(:thumbnail) { create :vcs_file_thumbnail }
        let(:version)   { VCS::Version.order(:created_at).first }
        before          { versionable.thumbnail = thumbnail }

        it 'updates thumbnail on the version' do
          expect { versionable.save }
            .to change { version.reload.thumbnail_id }.from(nil)
        end
      end
    end
  end

  describe 'validation: current version must belong to versionable' do
    let(:other_version) { create :vcs_version }
    before              { versionable.current_version = other_version }

    it 'adds error: must belong to versionable' do
      expect(versionable).to be_invalid
      expect(versionable.errors[:current_version])
        .to contain_exactly "must belong to this #{versionable_model_name}"
    end
  end
end
