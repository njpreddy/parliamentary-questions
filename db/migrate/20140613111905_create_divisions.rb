class CreateDivisions < ActiveRecord::Migration[5.0]
  def change
    create_table :divisions do |t|
      t.string :name
      t.integer :directorate_id
      t.boolean	:deleted
      t.timestamps
    end
  end
end
