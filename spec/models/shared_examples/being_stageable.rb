# frozen_string_literal: true

RSpec.shared_examples 'being stageable' do
  describe 'associations' do
    it do
      is_expected
        .to have_many(:stagings)
        .class_name('StagedFile')
        .dependent(:restrict_with_exception)
    end
    it do
      is_expected
        .to have_many(:staging_projects)
        .class_name('Project')
        .through(:stagings)
        .source(:project)
    end
    it do
      is_expected
        .to have_many(:non_root_stagings)
        .class_name('StagedFile')
        .dependent(false)
    end
    it do
      is_expected
        .to have_many(:non_root_staging_projects)
        .class_name('Project')
        .through(:non_root_stagings)
        .source(:project)
    end
  end

  describe 'callback: after_save' do
    subject                 { stageable }
    let(:parent_id_changed) { false }

    before do
      allow(stageable)
        .to receive(:saved_change_to_parent_id?).and_return parent_id_changed
    end
    after { stageable.save }
    it    { is_expected.not_to receive(:restage) }

    context 'when parent id changed' do
      let(:parent_id_changed) { true }
      it { is_expected.to receive(:restage) }
    end
  end

  describe '#restage' do
    let(:parent) { nil }

    before  { allow(stageable).to receive(:parent).and_return parent }
    after   { stageable.send :restage }

    it do
      expect(stageable).to receive(:non_root_staging_project_ids=).with(nil)
    end

    context 'when parent exists' do
      let(:parent)      { instance_double described_class }
      let(:project_ids) { [1, 2, 3] }

      before do
        allow(parent).to receive(:staging_project_ids).and_return project_ids
      end

      it do
        expect(stageable)
          .to receive(:non_root_staging_project_ids=).with([1, 2, 3])
      end
    end
  end
end
