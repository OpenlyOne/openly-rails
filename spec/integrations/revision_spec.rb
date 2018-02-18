# frozen_string_literal: true

RSpec.describe Revision, type: :model do
  subject(:revision) { build(:revision) }

  describe 'validation: parent must belong to same project' do
    let(:parent)        { create(:revision) }
    before              { revision.parent = parent }

    context 'when parent revision belongs to different project' do
      before  { revision.project = create(:project) }
      it      { is_expected.to be_invalid }
    end

    context 'when parent revision belongs to same project' do
      before  { revision.project = parent.project }
      it      { is_expected.to be_valid }
    end
  end

  describe 'validation: can have only one origin revision per project' do
    subject(:new_origin) { build(:revision, project: project) }
    let(:project)        { create(:project) }

    context 'when published origin revision exists in project' do
      let!(:existing_origin) { create :revision, :published, project: project }
      it                     { is_expected.to be_invalid }
    end

    context 'when origin revision in project is not published' do
      let!(:existing_origin) { create :revision, project: project }
      it                     { is_expected.to be_valid }
    end

    context 'when origin revision exists in another project' do
      let!(:existing_origin) { create :revision, :published }
      it { is_expected.to be_valid }
    end
  end

  describe 'validation: can have only one revision with parent' do
    subject(:revision)  { build(:revision, parent: parent) }
    let(:parent)        { create(:revision) }

    context 'when revision with same parent exists' do
      let!(:existing) { create :revision, :published, parent: parent }
      it              { is_expected.to be_invalid }
    end

    context 'when revision with same parent is not published' do
      let!(:existing) { create :revision, parent: parent }
      it              { is_expected.to be_valid }
    end

    context 'when revision with same parent does not exist' do
      let!(:existing) { create :revision, :with_parent }
      it              { is_expected.to be_valid }
    end
  end
end
