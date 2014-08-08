class CreateApprovableChangeRequests < ActiveRecord::Migration
  def change
    create_table :approvable_change_requests do |t|
      t.string :approvable_type
      t.integer :approvable_id
      t.json :requested_changes
      t.string :state
      t.string :approver_type
      t.integer :approver_id
      
      t.timestamps
    end
  end
end
