class AddNotesToApprovableChangeRequests < ActiveRecord::Migration
  def change
    add_column :approvable_change_requests, :notes, :json
  end
end
