class Group < ActiveRecord::Base
  has_many :memberships, class_name: "GroupMembership"
  has_many :members, through: :memberships, source: :user
  has_many :threads, class_name: "MessageThread"
  has_one :profile, class_name: "GroupProfile"

  validates :name, :short_name, presence: true

  after_create :create_default_profile, unless: :profile

  def committee_members
    members.where("group_memberships.role = 'committee'")
  end

  def normal_members
    members.where("group_memberships.role = 'member'")
  end

  def to_param
    "#{id}-#{short_name}"
  end

  protected

  def create_default_profile
    build_profile.save!
  end
end
