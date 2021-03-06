# == Schema Information
#
# Table name: user_profiles
#
#  id          :integer          not null, primary key
#  user_id     :integer          not null
#  picture_uid :string(255)
#  website     :string(255)
#  about       :text
#  visibility  :string(255)      default("public"), not null
#
# Indexes
#
#  index_user_profiles_on_user_id  (user_id)
#

class UserProfile < ActiveRecord::Base
  VISIBILITY_OPTIONS = %w(public group).freeze

  dragonfly_accessor :picture do
    storage_options :generate_picture_path
  end

  belongs_to :user

  validates :website, url: true
  validates :visibility, inclusion: { in: VISIBILITY_OPTIONS }

  validates_property :mime_type, of: :picture, in: %w(image/jpeg image/png image/gif)

  def website=(val)
    write_attribute(:website, AttributeNormaliser::URL.new(val).normalise)
  end

  def picture_thumbnail
    picture.thumb('50x50>')
  end

  def clear
    update(picture: nil, website: nil, about: nil)
  end

  protected

  def generate_picture_path
    hash = Digest::SHA1.file(picture.path).hexdigest
    {path: "profile_pictures/#{hash[0..2]}/#{hash[3..5]}/#{hash}"}
  end
end
