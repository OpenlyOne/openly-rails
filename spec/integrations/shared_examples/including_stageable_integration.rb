# frozen_string_literal: true

RSpec.shared_examples 'including stageable integration' do
  subject(:staged_projects) { stageable.staging_projects.to_a }
  let(:p1) { create :project }
  let(:p2) { create :project }
  let(:p3) { create :project }
  let(:p4) { create :project }
  let(:p5) { create :project }
  let(:p6) { create :project }

  before { parent.staging_projects = [p1, p2, p3, p4] }

  describe 'parent is set to nil' do
    before { stageable.update(parent: nil) }
    it     { is_expected.to eq [] }
  end

  describe 'parent is set from nil' do
    before { stageable.update(parent: parent) }
    it     { is_expected.to contain_exactly(p1, p2, p3, p4) }
  end

  describe 'parent is updated' do
    let(:new_parent) { described_class.new(attributes) }
    let(:attributes) { parent.dup.attributes.except('current_snapshot_id') }

    before do
      # Create new parent with staged projects
      new_parent.update(external_id: 'new-parent')
      new_parent.staging_projects = staging_projects_of_new_parent

      # Update stageable from parent to new_parent
      stageable.update(parent: parent)
      stageable.update(parent: new_parent)
    end

    describe 'parent is staged in some projects' do
      let(:staging_projects_of_new_parent) { [p3, p4, p5, p6] }

      it { is_expected.to contain_exactly(p3, p4, p5, p6) }
    end

    describe 'parent is staged in no projects' do
      let(:staging_projects_of_new_parent) { [] }

      it { is_expected.to eq [] }
    end
  end

  describe 'stageable is root in p1, p2, p3' do
    before do
      p1.root_folder = stageable
      p2.root_folder = stageable
      p3.root_folder = stageable
    end

    before { parent.staging_projects = [p4, p5, p6] }

    it 'does not delete stagings as root' do
      stageable.update(parent: parent)
      is_expected.to contain_exactly(p1, p2, p3, p4, p5, p6)
    end
  end
end
