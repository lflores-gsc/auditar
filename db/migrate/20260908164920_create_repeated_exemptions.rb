class CreateRepeatedExemptions < ActiveRecord::Migration[8.1]
  def change
    create_table :repeated_exemptions do |t|
      t.string :cuenta
      t.string :catastral
      t.string :nombre
      t.string :ubicacion
      t.string :desarrollo
      t.string :l
      t.string :m
      t.string :index
      t.string :reason

      t.timestamps
    end
  end
end
