require 'hsmty/api'
require 'test/unit'
require 'rack/test'

require 'json'
require 'sequel'
require 'bcrypt'

class APITest < Test::Unit::TestCase
    include Rack::Test::Methods
    @@uuid = '0000000000000'
    @@token = '012345689ABCD'
    @@key = 'supersecretkey'
    @@test_endpoint = 'http://test/status.json'
    @@db = '/tmp/hsmty.db'

    def app
        Sinatra::Application
    end

    def test_token_list
        get '/idevices'
        assert last_response.ok?
    end

    def test_register
        create_test_endpoint
        device = {
            'uuid' => @@uuid,
            'token' => @@token,
            'secret' => @@key,
            'version' => 0,
            'spaceapi' => [
                @@test_endpoint
                ]
            }
        body = device.to_json
        put '/idevices/' + @@token, body
        assert_equal 201, last_response.status, 
            'Failed to register the device: ' + @@token
        put '/idevices/' + @@token, body
        assert_equal 409, last_response.status,
            'Conflict not reported correctly for: ' + @@token
        delete_device
        device['spaceapi'] = [
            "http://acemonstertoys.org/status.json",
            "https://ackspace.nl/status.php",
            ]
        put '/idevices/' + @@token, device.to_json
        assert_equal 201, last_response.status
        get '/idevices/' + @@token
        assert last_response.ok?
        delete_device
    end

    def create_device
        hash = BCrypt::Password.create(@@pass)
        db = Sequel.sqlite(@@db)
        db[:idevices].insert(
            :uuid => @@uuid,
            :token => @@token,
            :secret => @@key,
            :version => '0.1'
        )
    end

    def delete_device
        db = Sequel.sqlite(@@db)
        db[:idevices].where(:uuid => @@uuid).delete
    end

    def clear_updates
        db = Sequel.sqlite(@@db)
        db[:idevices_spaces].delete
    end

    def create_test_endpoint
        db = Sequel.sqlite(@@db)
        db[:spaces].insert(:name => 'Test', :url => @@test_endpoint)
    end

    def delete_test_endpoint
        db = Sequel.sqlite(@@db)
        db[:spaces].where(:url => @@test_endpoint).delete
    end
end
