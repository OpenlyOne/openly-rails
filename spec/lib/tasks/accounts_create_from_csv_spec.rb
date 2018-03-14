# frozen_string_literal: true

require 'lib/shared_contexts/rake.rb'

RSpec.describe 'accounts:create_from_csv' do
  include_context 'rake'

  let(:task_path)   { "lib/tasks/#{task_name.tr(':', '/')}" }
  let(:path_to_csv) { 'spec/support/fixtures/accounts/import.csv' }

  let(:account1)    { Account.find_by_email('a1@example.com') }
  let(:account2)    { Account.find_by_email('a2@example.com') }
  let(:account3)    { Account.find_by_email('a3@example.com') }

  before { allow(STDOUT).to receive(:puts) }
  before { subject.invoke(path_to_csv) }

  it 'creates three users' do
    expect(Account.count).to eq 3

    expect(account1).to be_valid_password 'a1password'
    expect(account1.user.name).to eq 'Account 1 Name'
    expect(account1.user.handle).to eq 'account1'

    expect(account2).to be_valid_password 'a2password'
    expect(account2.user.name).to eq '2nd Account Name'
    expect(account2.user.handle).to eq 'accountnrtwo'

    expect(account3).to be_valid_password 'a3password'
    expect(account3.user.name).to eq 'Third Account'
    expect(account3.user.handle).to eq '3rdaccount'
  end
end
