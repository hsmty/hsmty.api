require 'sinatra'
require 'json'
require 'bcrypt'
require 'sequel'
require 'openssl'
require 'securerandom'

load 'conf.rb'

helpers do

    def protected!
        return if authorized?
        headers['WWW-Authenticate'] = 'Basic realm="Restricted Area"'
        halt 401, "Not authorized\n"
    end

    def authorized?
        @auth ||=  Rack::Auth::Basic::Request.new(request.env)
        user, pass, stored = nil
        if @auth.provided? and @auth.basic? and @auth.credentials then
            db = getdbh()
            user, pass = @auth.credentials
            hash = db[:users].where(:nick => user).get(:password)
            if hash
                stored = BCrypt::Password.new(hash)
            end			
        end

        if stored and stored == pass then
            return true
        end

        return false
    end

    def signed!
        return if request["X-Content-HMAC"]
        status 412
        halt 412, "Content HMAC missing\n"
    end

end

get '/' do
    'HSMTY API'
end

get '/status.json' do

    status = make_status()

    headers "Content-type" => 'application/json'
    status.to_json
end

post '/status' do
    protected!

    status = params[:status]

    if status == 'open'
        status = true
    elsif status == 'close'
        status = false
    else
        halt 400
    end

    db = getdbh()
    current = db[:status].reverse_order(:changed).get(:state)

    if status != current

        db[:status].insert(:state => status, :changed => Time.now().to_i)
    end
    
    'Updated'
end

get '/status/events' do
    db = getdbh()
    events = db[:events].all    
    return events.to_json
end

post '/status/events' do
    protected!

    name = params[:name]
    type = params[:type]

    if type.nil?
        halt 400, 'Missing event type'
    end

    unless name
        halt 400, 'Missing name for event'
    end

    uid = get_uid()
    db = getdbh()
    db[:events].insert(
        :name => name,
        :time => Time.now.to_i,
        :type => type,
        :created_by => uid
        )

    "Event Saved"
end

get '/status/happenings' do
    db = getdbh()
    events = db[:happenings].all    
    return events.to_json
end

post '/status/happenings' do
    protected!

    name = params[:name]
    time = params[:time].to_i
    cost = params[:cost]

    if time.to_i < Time.now().to_i 
        halt 400, 'Time is before now'
    end

    unless name
        halt 400, 'Missing name for event'
    end

    uid = get_uid()
    db = getdbh()
    id = db[:happenings].insert(
        :name => name,
        :time => time,
        :cost => cost,
        :created => Time.now.to_i,
        :created_by => uid
        )
    "Event Saved"

end

get '/idevices/?' do
    db = getdbh()
    count = db[:idevices].count
    return {
        :devices => count
    }.to_json
end

get '/idevices/:token' do |token|
    db = getdbh()
    spaces = []

    begin
        db[:idevices_spaces].join(:idevices).
            where(:token => token).map { |space|
                spaces.push(space[:space_id])
            }
        {
            :spaceapi => spaces
        }.to_json
    rescue
        status 404
        {
            :error => 404,
            :msg => 'Device not found'
        }.to_json
    end
end

put '/idevices/:token' do |token|
    request.body.rewind
    reg = JSON.parse(request.body.read)
    db = getdbh

    unless valid_token?(token)
        status 403
        return 'Invalid token'
    end

    device_id = nil
    secret = SecureRandom.hex

    record = db[:idevices].where(:token => token).get(:id)
    if record
        status 409
        return "409 Conflict\nToken already exists\n"
    end

    begin
        device_id = db[:idevices].insert(
            :secret => secret,
            :token  => token,
            :version => 0
        )
    rescue
        status 500
    end

    if reg["spaceapi"].kind_of?(Array)
        if save_uris(token, reg['spaceapi']) < 0
            db[:idevices].where(:token => token).delete
            status 400
            return {"error" => "Error saving subscriptions"}.to_json
        end
    end

    status 201
    return { "secret" => secret }.to_json

end

post '/idevices/:token' do |token|
    signed!
    request.body.rewind
    req = JSON.parse(request.body.read)
    hmac = request['X-Content-HMAC']

    unless valid_signature?(data, token, hmac) then
        status 400
        return { "error" => "Invalid signature"}.to_json
    end

    if defined? req['spaceapi']['add']  and req['spaceapi']['add'].kind_of?(Array)

        save_uris(token, req['spaceapi']['add'])

    end

    if defined? req['spaceapi']['del'] then
    end

    status 200
    return {"status" => "URIs Updated!"}.to_json
end
        
def save_uris(token, urls)
    db = getdbh()
    status = 1
    begin
        urls.each do |url|
            space = db[:spaces].where(:url => url).get(:id)
            device = db[:idevices].where(:token => token).get(id)
            db[:idevices_spaces].insert(
                :idevice => token, 
                :space => id
            )
            status += 1
        end
    rescue
        status = -1
    end

    return status
end

def make_status()
    db = getdbh()

    file = open('status.json')
    status = JSON.parse(file.read)

    if (status and status['state']) then
        row = db[:status].reverse_order(:changed)
        status['state'][:open] = row.get(:state)
    else
        status = {}
    end

    return status
end

def valid_signature?(data, token, hmac, hash='sha256')
    db = getdbh()

    # If anything goes wrong we should return false.
    # And we do!
    begin
        secret = db[:idevices].where(:token => token).get(:secret)

        unless secret
            return false
        end

        check = OpenSSL::HMAC.hexdigest(OpenSSL::Digest::Digest.new(hash), key, data)

        if hmac == check then
            return true
        end
    end

    return false
end

def valid_token?(token)
    return true
end

def get_uid()
    db = getdbh()
    user, pass = @auth.credentials
    id = db[:users].where(:nick => user).get(:id)
end

def getdbh()
    if settings.db_engine == :sqlite
        dbh = Sequel.sqlite('/tmp/hsmty.db')
    else
        dbh = nil
    end

    return dbh
end
