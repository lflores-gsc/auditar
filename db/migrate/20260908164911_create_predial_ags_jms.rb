class CreatePredialAgsJms < ActiveRecord::Migration[8.1]
  def change
    create_table :predial_ags_jms do |t|
      t.string :cuenta
      t.string :catastral
      t.string :nombre
      t.string :ubicacion
      t.string :desarrollo
      t.string :l
      t.string :m
      t.string :index

      t.timestamps
    end
    add_index :predial_ags_jms, :index, unique: true
  end
end
