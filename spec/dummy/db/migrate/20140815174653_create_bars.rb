class CreateBars < ActiveRecord::Migration
  def change
    create_table :bars do |t|
      t.string :title
      t.integer :listing_id

      t.timestamps
    end
  end
end
