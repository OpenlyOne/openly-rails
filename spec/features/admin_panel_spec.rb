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
  end
end
