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
