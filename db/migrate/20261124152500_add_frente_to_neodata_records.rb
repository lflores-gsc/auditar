class AddFrenteToNeodataRecords < ActiveRecord::Migration[8.1]
  def change
    add_column :neodata_records, :frente, :string, limit: 3
  end
end
