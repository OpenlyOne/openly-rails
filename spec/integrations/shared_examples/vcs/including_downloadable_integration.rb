# frozen_string_literal: true

RSpec.shared_examples 'vcs: including downloadable integration', :vcr do
  let(:file) do
    create :vcs_file_in_branch,
           remote_file_id: remote_file.id, parent_in_branch: root
  end
  let(:remote_file) do
    file_sync_class.create(
      name: 'Test File',
      parent_id: parent_id,
      mime_type: mime_type
    )
  end

  it 'downloads content on save' do
    remote_file.update_content('This is my content')
    file.pull
    expect(file.reload.content.plain_text).to eq 'This is my content'
  end

  context 'when content has already been downloaded' do
    it 'does not re-download the content' do
      remote_file.update_content('This is my content')
      file.pull
      file.content.update(plain_text: 'other text')
      expect { file.pull }.not_to(change { file.reload.content.plain_text })
    end
  end
end
