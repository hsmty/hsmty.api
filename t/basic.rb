require 'hsmty/api'
require 'test/unit'
require 'rack/test'

require 'json'
require 'sequel'
require 'bcrypt'

class APITest < Test::Unit::TestCase
    include Rack::Test::Methods
    @@user = '__tester'
    @@pass = 'supersecretpassword'
    @@db = '/tmp/hsmty.db'

    def app
        Sinatra::Application
    end

    def test_index
        get '/'
        assert last_response.ok?
    end

    def test_status
        get '/status.json'
        assert last_response.ok?
        assert_equal 'application/json', last_response.header['Content-type']
    end

    def test_update_status
        create_user
        post '/status', :status => 'open'
        assert_equal 401, last_response.status
        authorize @@user, @@pass
        post '/status', :status => 'open'
        assert_equal 200, last_response.status
        get '/status.json'
        status = JSON.parse(last_response.body)
        assert status['state']['open'], "Didn't update status as open"
        sleep(1) # Avoid race condition
        post '/status', :status => 'close'
        get '/status.json'
        status = JSON.parse(last_response.body)
        assert_equal false, status['state']['open'], "Didn't update status as close"
        delete_user
    end

    def test_events
        create_user # Creates a Test user
        name = 'Test event'
        start = Time.now().to_i + 3600
        clear_events

        get '/status/events'
        assert last_response.ok?
        post '/status/events',
            :time => start,
            :name => name
        assert_equal 401, last_response.status, 
            "It shouldn't give us access without auth"
        authorize @@user, @@pass
        post '/status/events',
            :time => start,
            :name => name
        assert_equal 200, last_response.status, 
            "Error authorizing the request"
        get '/status/events'
        assert last_response.ok?
        events = JSON.parse(last_response.body)
        assert_equal 1, events.length,
            "Event didn't get saved"
        delete_user # Clean ourselves
    end

    def create_user
        hash = BCrypt::Password.create(@@pass)
        db = Sequel.sqlite(@@db)
        db[:users].insert(
            :nick => @@user,
            :password => hash.to_s
        )
    end

    def delete_user
        db = Sequel.sqlite(@@db)
        db[:users].where(:nick => @@user).delete
    end

    def clear_events
        db = Sequel.sqlite(@@db)
        db[:events].delete
    end
end
