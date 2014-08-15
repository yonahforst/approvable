class Listing < ActiveRecord::Base
  validates :title, presence: true
  has_one :foo
  has_many :bars
  acts_as_approvable
end
