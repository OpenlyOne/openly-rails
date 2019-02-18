# frozen_string_literal: true

feature 'Contributions: Replies' do
  let(:project)       { contribution.project }
  let(:contribution)  { create :contribution, :mock_setup }
  let(:replies)       { create_list :reply, 3, contribution: contribution }

  before { sign_in_as project.owner.account }

  scenario 'User can read contribution discussion' do
    # given there is a contribution
    contribution

    # and it has replies
    replies

    # when I visit the project
    visit profile_project_path(project.owner, project)

    # and navigate to the contribution
    click_on 'Contributions'
    click_on contribution.title

    # then I should see the contribution description and 3 replies in
    # chronological order
    expect(page.find_all('.reply:not(.form)').map(&:text))
      .to eq [contribution.description] + replies.map(&:content)
  end

  scenario 'User can reply to contribution discussion' do
    # given there is a contribution
    contribution

    # and it has replies
    replies

    # when I visit the project
    visit profile_project_path(project.owner, project)

    # and navigate to the contribution
    click_on 'Contributions'
    click_on contribution.title

    # and submit a new reply
    fill_in 'Your Reply', with: 'I think this is a great contribution!'
    click_on 'Reply'

    # then I should see the new reply on the page
    expect(page).to have_text 'Reply successfully created'
    expect(page).to have_text 'I think this is a great contribution'
  end
end
