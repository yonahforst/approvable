class Foo < ActiveRecord::Base
  belongs_to :listing
  acts_as_approvable except: :listing_id
end
