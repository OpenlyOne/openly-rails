# frozen_string_literal: true

RSpec.describe Profiles::User, type: :model do
  subject(:user) { build :user }

  describe 'attachment: picture' do
    subject(:method) { user.picture = picture }
    let(:picture) do
      File.new(
        Rails.root.join('spec', 'support', 'fixtures', 'profiles',
                        'picture.jpg')
      )
    end

    it 'stores at :attachment_path/profiles/000/000/00x/picture' do
      method
      user.save

      # id to partition: 000/000/00X
      # Source: paperclip/lib/paperclip/interpolations.rb
      id_partition = format('%09d', user.id).scan(/\d{3}/).join('/')
      picture_path = Rails.root.join(Settings.attachment_storage, 'profiles',
                                     id_partition, 'picture')

      expect(File).to be_exists picture_path.join('original.jpg')
      expect(File).to be_exists picture_path.join('large.jpg')
      expect(File).to be_exists picture_path.join('medium.jpg')
    end

    it 'accesses at :attachment_url/profiles/000/000/00x/picture' do
      method
      user.save

      # id to partition: 000/000/00X
      # Source: paperclip/lib/paperclip/interpolations.rb
      id_partition = format('%09d', user.id).scan(/\d{3}/).join('/')
      picture_url =
        Pathname('/').join(Settings.attachment_storage.gsub(/^public/, ''),
                           'profiles', id_partition, 'picture', 'medium.jpg')
                     .to_s

      expect(user.picture.url).to be_starts_with picture_url
    end
  end
end
