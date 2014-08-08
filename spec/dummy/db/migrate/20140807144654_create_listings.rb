class CreateListings < ActiveRecord::Migration
  def change
    create_table :listings do |t|
      t.string :title
      t.text :description
      t.string :image
      t.boolean :deleted

      t.timestamps
    end
  end
end
