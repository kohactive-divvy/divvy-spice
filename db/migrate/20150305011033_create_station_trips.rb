class CreateStationTrips < ActiveRecord::Migration
  def change
    create_table :station_trips do |t|
      t.integer :from_station_id, index: true
      t.integer :to_station_id, index: true
      t.integer :trip_count
      t.integer :average_duration
      t.integer :fastest_trip
      t.integer :slowest_trip
      t.timestamps null: false
    end
  end
end
