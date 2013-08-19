require 'sinatra'
require 'json'
require 'bcrypt'
require 'sequel'

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

    def check_key!
        return if valid_key?
        headers['WWW-Authenticate'] = 'Basic real="identification needed"'
        halt 401, "Not Authorized\n"
    end

    def valid_key?
        @auth ||= Rack::Auth::Basic::Request.new(request.env)
        uuid, key, stored = nil
        if @auth.provided? and @auth.basic and @auth.credentials then
            db = getdbh()
            uuid, key = @auth.credentials
            hash = db[:idevices].where(:uuid => uuid).get(:secret)
            stored = BCrypt::Password.new(hash)
        end

        if stored and stored == key then
            return true
        end

        return false
    end

end

error 400 do |mesg|
    if mesg then
        'Bad Request: #{mesg}'
    else
        'Bad Request'
    end
end

get '/' do
    'HSMTY API'
end

get '/status.json' do

    status = createstatus()

    headers "Content-type" => 'application/json'
    status.to_json
end

post '/status/update' do
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

get '/idevices/?' do
    db = getdbh()
    count = db[:idevices].count
    return {
        :devices => count
    }.to_json
end

get '/idevices/:token' do |token|
    check_key!
    db = getdbh()
    device = db[:idevices].where(:token => token).first
    if device then
        { :device => device[:id]}.to_json
    else
        status 404
        body ({
            :error => 404,
            :msg => 'Device not found'
        }.to_json)
    end
end

put '/idevices/:token' do |token|
    check_key!
    request.body.rewind
    reg = JSON.parse(request.body.read)
    if (reg and reg['id'] and reg['key']) then
        db = getdbh()
        db[:idevices].insert(
            :id  => reg['id'],
            :key => reg['key'],
            :token => token,
            :version => 0
        )
       
    elsif (reg)
        status 400
        body 'Missing params'
    else
        status 400
        body 'Invalid Request'
    end

end

post '/idevices/:token' do |token|
    check_key!
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
        
def createstatus()
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

def getdbh()
    dbh = Sequel.sqlite('/tmp/hsmty.db')
end
