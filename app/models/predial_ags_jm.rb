# == Schema Information
#
# Table name: predial_ags_jms
#
#  id         :bigint           not null, primary key
#  catastral  :string
#  cuenta     :string
#  desarrollo :string
#  index      :string
#  l          :string
#  m          :string
#  nombre     :string
#  ubicacion  :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_predial_ags_jms_on_index  (index) UNIQUE
#
class PredialAgsJM < ApplicationRecord
end
