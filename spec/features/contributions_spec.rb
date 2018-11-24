# frozen_string_literal: true

feature 'Revision' do
  let(:project)       { create :project, :setup_complete, :skip_archive_setup }
  let(:master_branch) { project.master_branch }
  let!(:root)         { create :vcs_staged_file, :root, branch: master_branch }

  scenario 'User can see contributions' do
    # given I am signed in as the project owner
    sign_in_as project.owner.account
    # and there are contributions
    contributions = create_list :contribution, 3, project: project

    # when I visit the project page
    visit "#{project.owner.to_param}/#{project.to_param}"
    # and click on Contributions
    click_on 'Contributions'

    # then I should see each contribution in reverse chronological order
    expect(page.find_all('.contribution .title b').map(&:text))
      .to eq contributions.reverse.map(&:title)
  end

  scenario 'User can create contribution' do
    # given I am signed in as the project owner
    sign_in_as project.owner.account

    # when I visit the project page
    visit "#{project.owner.to_param}/#{project.to_param}"
    # and click on Contributions
    click_on 'Contributions'
    # and click on New Contribution
    click_on 'New Contribution'
    # and enter a contribution title
    fill_in 'Title', with: 'A Contribution'
    fill_in 'Description', with: 'My new contribution'
    # and click on 'Create Contribution'
    click_on 'Create Contribution'

    # then I should be on the contribution page
    expect(page).to have_current_path(
      "/#{project.owner.to_param}/#{project.to_param}" \
      "/contributions/#{project.contributions.first.to_param}"
    )
    # and see a success message
    expect(page).to have_text 'Contribution successfully created.'
  end
end
