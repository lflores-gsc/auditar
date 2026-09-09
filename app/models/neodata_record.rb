# == Schema Information
#
# Table name: neodata_records
#
#  id              :bigint           not null, primary key
#  codigo_cliente  :string
#  index           :string
#  manzana         :string
#  nombre_cliente  :string
#  nombre_proyecto :string
#  num_lote        :string
#  vivienda        :string
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#
# Indexes
#
#  index_neodata_records_on_index  (index) UNIQUE
#
class NeodataRecord < ApplicationRecord
end
