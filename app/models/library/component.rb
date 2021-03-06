# Base class for implementing components of Library Items.
class Library::Component < ActiveRecord::Base

  self.abstract_class = true

  attr_accessor :created_by, :tags_string

  belongs_to :item, class_name: 'Library::Item', foreign_key: 'library_item_id'

  scope :recent, -> num { includes(:item).order('library_items.created_at DESC').limit(num) }

  before_create :create_library_item, unless: :item
  after_create :update_library_item

  validates :created_by, presence: true

  def created_by
    @created_by || item && item.created_by
  end

  def created_at
    item && item.created_at
  end

  protected

  def create_library_item
    item = build_item
    item.created_by = created_by
    item.tags_string = tags_string if tags_string
    item.save!
    self.item = item
  end

  def update_library_item
    item.update(component: self)
    Sunspot.index item
  end
end
