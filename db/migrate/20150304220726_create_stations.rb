class CreateStations < ActiveRecord::Migration
  def change
    create_table :stations do |t|
      t.string :name
      t.integer :station_id, index: true
      t.decimal :lat, { precision: 10, scale: 6 }
      t.decimal :lng, { precision: 10, scale: 6 }
      t.st_point :lnglat, geographic: true
      t.integer :capacity
      t.datetime :online_at
      t.timestamps null: false
    end
  end
end
