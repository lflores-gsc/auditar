module DesarrolloNormalizer
  ROMAN_MAP = {
    "I" => 1, "II" => 2, "III" => 3, "IV" => 4, "V" => 5,
    "VI" => 6, "VII" => 7, "VIII" => 8, "IX" => 9, "X" => 10
  }.freeze

  def roman_to_int(roman)
    ROMAN_MAP[roman]
  end

  def extract_desarrollo(val)
    return "" if val.nil?
    str = val.to_s.strip.upcase

    # Remove known prefixes
    str = str.sub(/\AF\s*\d+\s*/, "")   # e.g. "F 101 "
    str = str.sub(/\ARESERVA\s+/, "")   # e.g. "RESERVA "

    # Remove leading articles: LA, EL, LOS, LAS
    str = str.sub(/\A(LA|EL|LOS|LAS)\s+/, "")

    # Match trailing roman numeral
    if str =~ /\s+(X|IX|VIII|VII|VI|V|IV|III|II|I)\z/
      roman = $1
      str = str.sub(/\s+#{roman}\z/, roman_to_int(roman).to_s)
    end

    # Remove ALL spaces from the final result
    str.gsub(/\s+/, "")
  end
end

