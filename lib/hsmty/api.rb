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


    if status != current then

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

    unless valid_token?(token)
        status 403
        return 'Invalid token'
    end

    device_id = nil
    secret = SecureRandom.hex

    begin
        device_id = db[:idevices].insert(
            :secret => secret,
            :token  => token,
            :version => 0
        )
    rescue
        status 500
    end

    if reg['spaceapi'].kind_of?(Array)
        reg['spaceapi'].each do |uri|
            space = db[:spaces].where(:uri => uri).get(:id)
            if space
                db[:idevices_spaces].insert(
                    :idevice => device_id, 
                    :space => space
                    )
            else
                db[:idevices].where(:token => token).delete
                status 400
                'Invalid URI'
            end
        end
    end

    status 201

end

post '/idevices/:token' do |token|
    request.body.rewind
    req = JSON.parse(request.body.read)

    if defined? req['spaceapi']['add'] then
        db = getdbh()
        req['spaceapi']['add'].each do |url|
            id = db[:spaces].where(:url => url).get(:name)
            db[:spaces_idevices].insert(
                :token => token, 
                :space => id
            )
        end
    end

    if defined? req['spaceapi']['del'] then
    end
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

def valid_signature?(token, data, signature, hash='sha256')
    db = getdbh()

    # If anything goes wrong we should return false.
    # And we do!
    begin
        secret = db[:idevices].where(:token => token).get(:secret)
        check = OpenSSL::HMAC.hexdigest(OpenSSL::Digest::Digest.new(hash), key, data)

        if signature == check then
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
