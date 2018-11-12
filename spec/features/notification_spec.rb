# frozen_string_literal: true

feature 'Notification' do
  # HACK: Turn off bullet
  # TODO: Figure out a long-term strategy for notifications that need to load
  # =>    associated objects. Could be anything from projects to users to
  # =>    pull requests.
  let!(:was_bullet_enabled) { Bullet.enable? }

  before  { Bullet.enable = false }
  after   { Bullet.enable = was_bullet_enabled }

  scenario 'User can see all notifications' do
    # given I have an account
    account = create(:account)
    # and I have three notifications
    create_list(:notification, 3, target: account)
    # and other accouns have 2 notifications
    create_list(:notification, 2)
    # and I am logged in
    sign_in_as account

    # when I visit my notifications
    visit notifications_path

    # then I should see my own notifications
    expect(page).to have_css '.notification', count: 3
  end

  scenario 'User can follow a notification' do
    # given I have an account
    account = create :account
    # and there is a project with a revision
    project = create :project, :setup_complete, :skip_archive_setup
    revision = create :vcs_commit, branch: project.master_branch
    # and I have a notification for the revision
    create(:notification, target: account, notifiable: revision)
    # and I am logged in
    sign_in_as account

    # when I visit my notifications
    visit notifications_path
    # and click on the notification
    find('.notification').click

    # then I should be on the revisions page
    project = Project.find_by_repository_id(revision.repository.id)
    expect(page).to have_current_path(
      profile_project_revisions_path(project.owner, project)
    )
    # and have no unread notifications
    expect(account).not_to have_unopened_notifications
  end
end
