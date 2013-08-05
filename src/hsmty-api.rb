
require 'sinatra'
require 'json'
require 'sequel'

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
    # restricted!
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
        row = db[:status].select(:state).reverse_order(:changed).limit(1).first
        status['state'][:open] = row[:state]
    else
        status = {}
    end

    return status
end

def getdbh()
    dbh = Sequel.sqlite('/tmp/hsmty.db')
end
