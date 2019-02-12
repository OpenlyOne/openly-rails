# frozen_string_literal: true

RSpec.describe Profiles::User, type: :model do
  subject(:user) { build :user }

  describe 'attachment: picture' do
    subject(:method) { user.picture = picture }
    let(:picture_fixture_path) do
      Rails.root.join('spec', 'support', 'fixtures', 'profiles')
    end
    let(:picture) { File.new(picture_fixture_path.join('picture.jpg')) }
    let(:path_to_image_with_exif_data) do
      picture_fixture_path.join('image_with_exif_data.jpg')
    end
    let(:image_with_exif_data) { File.new path_to_image_with_exif_data }

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

    it 'strips exif metadata from uploaded image' do
      exif_data = `identify -verbose #{path_to_image_with_exif_data}`
      expect(exif_data).to match(/exif:/)

      user.picture = image_with_exif_data
      user.save
      uploaded_image = user.picture.path

      exif_data = `identify -verbose #{uploaded_image}`

      expect(exif_data).not_to match(/exif:/)
    end
  end

  describe 'attachment: banner' do
    subject(:method) { user.banner = banner }
    let(:picture_fixture_path) do
      Rails.root.join('spec', 'support', 'fixtures', 'profiles')
    end
    let(:banner) { File.new(picture_fixture_path.join('banner.jpg')) }
    let(:path_to_image_with_exif_data) do
      picture_fixture_path.join('image_with_exif_data.jpg')
    end
    let(:image_with_exif_data) { File.new path_to_image_with_exif_data }

    it 'stores at :attachment_path/profiles/000/000/00x/banner' do
      method
      user.save

      # id to partition: 000/000/00X
      # Source: paperclip/lib/paperclip/interpolations.rb
      id_partition = format('%09d', user.id).scan(/\d{3}/).join('/')
      banner_path = Rails.root.join(Settings.attachment_storage, 'profiles',
                                    id_partition, 'banner')

      expect(File).to be_exists banner_path.join('original.jpg')
    end

    it 'accesses at :attachment_url/profiles/000/000/00x/banner' do
      method
      user.save

      # id to partition: 000/000/00X
      # Source: paperclip/lib/paperclip/interpolations.rb
      id_partition = format('%09d', user.id).scan(/\d{3}/).join('/')
      banner_url =
        Pathname('/').join(Settings.attachment_storage.gsub(/^public/, ''),
                           'profiles', id_partition, 'banner', 'original.jpg')
                     .to_s

      expect(user.banner.url).to be_starts_with banner_url
    end

    it 'strips exif metadata from uploaded image' do
      exif_data = `identify -verbose #{path_to_image_with_exif_data}`
      expect(exif_data).to match(/exif:/)

      user.banner = image_with_exif_data
      user.save
      uploaded_image = user.banner.path

      exif_data = `identify -verbose #{uploaded_image}`

      expect(exif_data).not_to match(/exif:/)
    end
  end

  describe '#can_create_private_projects?' do
    context 'when user account is free' do
      subject(:user) { create(:user, :free) }

      it { is_expected.not_to be_can_create_private_projects }
    end

    context 'when user account is premium' do
      subject(:user) { create(:user, :premium) }

      it { is_expected.to be_can_create_private_projects }
    end
  end
end
