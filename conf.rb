configure do
    set :db_engine, :postgres
    set :db_name, 'hsmty-api'
    set :idevice_key, '0123456789ABCDEF'
    set :db_user, 'devel'
    set :db_pass, 'devel'
    set :db_host, 'localhost'
end

configure :test do
    set :db_engine, :sqlite
    set :db_name, '/tmp/hsmty.db'
    set :idevice_key, '0123456789ABCDEF'
end
