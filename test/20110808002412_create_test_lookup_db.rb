class CreateTestLookupDb < ActiveRecord::Migration
  def self.up
    create_table :cars do |t|
      t.integer :kind
      t.integer :color
      t.string :name

      t.timestamps
    end
    
    create_table :car_kinds do |t|
      t.string :name
    end
    create_table :planes do |t|
      t.integer :kind
      t.string :name

      t.timestamps
    end
    create_table :spaceships do |t|
      t.integer :cargo
      t.string :name

      t.timestamps
    end
    create_table :plane_kinds do |t|
      t.string :name
    end
    create_table :car_colors do |t|
      t.string :name
    end
    create_table :cargos do |t|
      t.string :name
    end
  end

  def self.down
    drop_table :cars
    drop_table :car_kinds
    drop_table :car_colors
    drop_table :planes
    drop_table :plane_kinds
    drop_table :spaceships
    drop_table :cargos
  end
end
