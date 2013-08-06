
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
        if (@auth.provided? and @auth.basic? and @auth.crentials) then
            db = getdbh()
            user, pass = @auth.credentials
            hash = db[:users].select(:pass).where(:nick => user).get
            stored = BCrypt::Password.new(hash)
        end

        if stored and stored == pass then
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

get '/status.json' do

    status = createstatus()

    status.to_json
end

post '/status/update' do
    protected!

    status = params[:status]
    unless status == :open or status == :close then
        halt 401
    end

    current = db[:status].select(:state).reverse_order(:changed).get

    if status != current then
        db[:status].insert(:status => status)
    end
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
    restricted!
    request.body.rewind
    req = JSON.parse(request.body.read)

    if defined? req['spaceapi']['add'] then
        db = getdbh()
        req['spaceapi']['add'].each do |url|
            id = db[:spaces].select(:name).where(:url => url).get 
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
        row = db[:status].select(:state).reverse_order(:changed)
        status['state'][:open] = row.get
    else
        status = {}
    end

    return status
end

def getdbh()
    dbh = Sequel.sqlite('/tmp/hsmty.db')
end
