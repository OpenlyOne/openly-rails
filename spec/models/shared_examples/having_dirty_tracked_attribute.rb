# frozen_string_literal: true

RSpec.shared_examples 'having a dirty-tracked attribute' do |attribute|
  let!(:new_value)  { 'new attribute value' }
  let!(:old_value)  { subject.send attribute }
  before            { subject.send "#{attribute}=", new_value }

  it 'equals new attribute value' do
    expect(subject.send(attribute)).to eq new_value
  end

  it '_was equals old attribute value' do
    expect(subject.send("#{attribute}_was")).to eq old_value
  end

  it 'has been changed' do
    expect(subject.send("#{attribute}_changed?")).to be true
  end

  it 'can be restored' do
    subject.send "restore_#{attribute}!"
    expect(subject.send(attribute)).to eq old_value
  end
end
