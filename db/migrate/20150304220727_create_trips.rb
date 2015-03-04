class CreateTrips < ActiveRecord::Migration
  def change
    create_table :trips do |t|
      t.integer :trip_id, index: true
      t.integer :duration
      t.integer :from_station_id
      t.integer :to_station_id
      t.string :user_type
      t.timestamps null: false
    end
  end
end
