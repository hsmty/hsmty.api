ENV['RACK_ENV'] = 'test'

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
        clean!
        create_test_endpoint
        device = {
            'token' => @@token,
            'secret' => @@key,
            'version' => 0,
            }
        body = device.to_json
        put '/idevices/' + @@token, body
        assert_equal 201, last_response.status, 
            'Failed to register the device: ' + @@token
        put '/idevices/' + @@token, body
        assert_equal 409, last_response.status,
            'Conflict not reported correctly for: ' + @@token
        clear_subscriptions
        delete_device
        device = {
            'spaceapi' => [
                "http://notvalid.test/status.json",
            ]
        }
        put '/idevices/' + @@token, device.to_json
        assert_equal 400, last_response.status, 
            "Should fail when registering an invalid URI"
        device['spaceapi'] = [
            @@test_endpoint
            ]
        put '/idevices/' + @@token, device.to_json
        assert_equal 201, last_response.status,
            "Failed creating a device with URI"
        get '/idevices/' + @@token
        assert last_response.ok?,
            "Failed retrieving the device"
    
        clean!
    end

    def create_device
        db = Sequel.sqlite(@@db)
        db[:idevices].insert(
            :token => @@token,
            :secret => @@key,
            :version => '0.1'
        )
    end

    def delete_device
        db = Sequel.sqlite(@@db)
        db[:idevices_spaces].delete
        db[:idevices].where(:token => @@token).delete
    end

    def clear_subscriptions
        db = Sequel.sqlite(@@db)
        db[:idevices_spaces].delete
    end

    def create_test_endpoint
        db = Sequel.sqlite(@@db)
        db[:spaces].insert(:name => 'Test', :uri => @@test_endpoint)
    end

    def delete_test_endpoint
        db = Sequel.sqlite(@@db)
        db[:spaces].where(:uri => @@test_endpoint).delete
    end

    def clean!
        delete_device
        clear_subscriptions
        delete_test_endpoint
    end
end
