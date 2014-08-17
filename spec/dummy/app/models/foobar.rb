class Foobar < ActiveRecord::Base
  acts_as_approvable

  store_accessor :json_hash, :foo, :bar
  
end
