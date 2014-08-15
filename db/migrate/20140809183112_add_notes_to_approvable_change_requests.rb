class AddNotesToApprovableChangeRequests < ActiveRecord::Migration
  def change
    add_column :approvable_change_requests, :notes, :json, default: {}
  end
end
