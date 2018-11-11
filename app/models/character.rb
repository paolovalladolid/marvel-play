class Character < ApplicationRecord
    attr_accessor :marvel_id, :name, :desc, :seed, :battle_word
    validates :seed, presence: true
    validates :seed, numericality: { only_integer: true, greater_than: 0, less_than: 10 }
    
    def auto_win?
        battle_word.present? && (battle_word.casecmp?("gamma") || battle_word.casecmp?("radioactive"))
    end
end
