require 'net/http'
require 'json'

class CharactersController < ApplicationController
    
    def new
    end
    
    def index
        if params[:name1] && params[:name2]
            @winner = nil
            lookup_characters(params)
            combat
        end
    end
    
    def show
    end
    
    private
    
    def combat
        if @winner.nil?
            @characters = @characters.sort{ |a, b| a.battle_word.length <=> b.battle_word.length  }.reverse
            @winner = @characters[0]
        end
    end
    
    def process_battle_word(marvel_char)
        if marvel_char.desc.blank?
            marvel_char.battle_word = ""
        else
            desc_array = marvel_char.desc.split
            index = marvel_char.seed.to_i - 1
            marvel_char.battle_word = desc_array[index]
        end
        if @winner.nil? && marvel_char.auto_win?
            @winner = marvel_char
        end
    end

    def process_character(marvel_char, seed)
        if marvel_char.present?
            # Get model from existing record or initialize new model
            existing = Character.find_or_initialize_by(name: marvel_char.name)

            # Update the fields of the existing model from the parsed model.  There might be a 
            # more efficient way to do this.
            existing.seed = seed
            existing.marvel_id = marvel_char.marvel_id
            existing.desc = marvel_char.desc
            
            # Save to invoke the validation mechanism
            existing.save
            
            # Figure out the battle word
            process_battle_word(existing)
            
            @characters << existing
        end
    end
    
    # Look up both Marvel characters
    def lookup_characters(params)
        @characters = Array.new
        character_result = marvel_lookup(params[:name1])
        process_character(character_result,  params[:seed])
        character_result = marvel_lookup(params[:name2])
        process_character(character_result,  params[:seed])
    end
    
    # Look up a Marvel character by name, using keys, timestamp, and generated
    # hash number.
    def marvel_lookup(name)
        public_key = 'd7625a1b12e996ec43328e82331a3176'
        private_key = '2aa476235a3bfc3f78c873a80cd88ef1669d58a8'
        marvel_char = nil
        
        begin
            uri = URI('http://gateway.marvel.com/v1/public/characters')
            params = Hash.new
            params["apikey"] = public_key
            params["ts"] = ts
            params["hash"] = request_hash(public_key,private_key)
            params["name"] = name
            uri.query = URI.encode_www_form(params)
         
            res = Net::HTTP.get_response(uri)

            # puts "response #{res.body}"
            body_h = JSON.parse(res.body)
            #puts body_h
            res_arr = body_h["data"]["results"]
            #puts res_arr
            res_arr.each do | char_item |
                #puts char_item
                marvel_char = Character.new
                marvel_char.marvel_id = char_item["id"]
                marvel_char.name = char_item["name"]
                marvel_char.desc = char_item["description"]
            end
        rescue => e
            puts "failed #{e}"
        end
        marvel_char
    end
    
    def request_hash(public_key,private_key)
        Digest::MD5.hexdigest("#{ts}#{private_key}#{public_key}")
    end

    def ts
        begin
            Time.now.to_i
        end
    end
end
