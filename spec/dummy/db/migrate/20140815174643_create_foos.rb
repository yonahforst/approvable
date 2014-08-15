class CreateFoos < ActiveRecord::Migration
  def change
    create_table :foos do |t|
      t.string :title
      t.integer :listing_id

      t.timestamps
    end
  end
end
