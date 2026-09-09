class CreateNeodataRecords < ActiveRecord::Migration[8.1]
  def change
    create_table :neodata_records do |t|
      t.string :vivienda
      t.string :nombre_cliente
      t.string :codigo_cliente
      t.string :nombre_proyecto
      t.string :manzana
      t.string :num_lote
      t.string :index

      t.timestamps
    end
    add_index :neodata_records, :index, unique: true
  end
end
