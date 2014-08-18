class Listing < ActiveRecord::Base
  validates :title, presence: true
  acts_as_approvable
end
