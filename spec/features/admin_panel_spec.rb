# frozen_string_literal: true

feature 'Admin Panel' do
  scenario 'Guest cannot access admin panel' do
    expect { visit '/admin' }.to raise_error(ActiveRecord::RecordNotFound)
  end

  scenario 'User cannot access admin panel' do
    account = create :account
    sign_in_as account

    expect { visit '/admin' }.to raise_error(ActiveRecord::RecordNotFound)
  end

  scenario 'Admin can access admin panel' do
    admin = create :account, :admin
    sign_in_as admin

    visit '/admin'
    expect(page).to have_text 'Accounts'
    expect(page).to have_link 'New account'
    expect(page).to have_text admin.email

    click_on 'Projects'
    click_on 'Profiles/Users'
  end

  scenario 'Accounts created default to non-premium' do
    admin = create :account, :admin
    sign_in_as admin

    # when I create a new account
    visit '/admin'
    click_on 'Accounts'
    click_on 'New account'
    fill_in 'Email', with: 'test@user.com'
    fill_in 'Password', with: 'password'
    fill_in 'Password confirmation', with: 'password'
    fill_in 'Name', with: 'Test User'
    fill_in 'Handle', with: 'testuser'
    click_on 'Create Account'

    # then the account should be created
    account = Account.find_by_email('test@user.com')
    expect(account).to be_present
    # and it should not be premium
    expect(account).not_to be_premium
  end
end

feature 'Analytics Dashboard' do
  scenario 'Guest cannot access admin panel' do
    expect { visit '/admin/analytics' }
      .to raise_error(ActiveRecord::RecordNotFound)
  end

  scenario 'User cannot access admin panel' do
    account = create :account
    sign_in_as account

    expect { visit '/admin/analytics' }
      .to raise_error(ActiveRecord::RecordNotFound)
  end

  scenario 'Admin can access admin panel' do
    admin = create :account, :admin
    sign_in_as admin

    visit '/admin/analytics'
    expect(page).to have_text 'New Query'
  end
end
