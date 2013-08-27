require 'hsmty/api'
require 'test/unit'
require 'rack/test'

require 'json'
require 'sequel'
require 'bcrypt'

class APITest < Test::Unit::TestCase
    include Rack::Test::Methods
    @@token = '__test_token'
    @@key = 'supersecretkey'
    @@db = '/tmp/hsmty.db'

    def app
        Sinatra::Application
    end

    def test_token_list
        get '/idevices'
        assert last_response.ok?
    end

    def create_token
        hash = BCrypt::Password.create(@@pass)
        db = Sequel.sqlite(@@db)
        db[:users].insert(
            :nick => @@user,
            :password => hash.to_s
        )
    end

    def delete_token
        db = Sequel.sqlite(@@db)
        db[:users].where(:nick => @@user).delete
    end

    def clear_updates
        db = Sequel.sqlite(@@db)
        db[:events].delete
    end
end
