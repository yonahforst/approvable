class Listing < ActiveRecord::Base
  acts_as_approvable
  
  validates :title, presence: true
end
