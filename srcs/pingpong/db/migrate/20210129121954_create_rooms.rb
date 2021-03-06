class CreateRooms < ActiveRecord::Migration[6.1]
  def change
    create_table :rooms do |t|
      t.string :name
      t.string :password
      t.timestamps
    end
    add_index :rooms, :name, unique: true
  end
end
