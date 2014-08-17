class CreateFoobars < ActiveRecord::Migration
  def change
    create_table :foobars do |t|
      t.json :json_hash

      t.timestamps
    end
  end
end
