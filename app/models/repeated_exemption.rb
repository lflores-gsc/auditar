# == Schema Information
#
# Table name: repeated_exemptions
#
#  id         :bigint           not null, primary key
#  catastral  :string
#  cuenta     :string
#  desarrollo :string
#  index      :string
#  l          :string
#  m          :string
#  nombre     :string
#  reason     :string
#  ubicacion  :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class RepeatedExemption < ApplicationRecord
end
