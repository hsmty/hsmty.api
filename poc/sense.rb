require "net/http"
require "uri"

MACS="/tmp/macs"
SERVER="api.hsmty.org"
PORT="80"

def get_macs()
    macs = []
    output = `arp-scan --localnet -q`
    output.each_line do |line|
        mac = filter_mac(line)
        macs.push(mac) if mac.length > 0
    end
    return macs;
end

def filter_mac(str)
    mac = str.match /([A-Fa-f0-9]{2}:?){6}/
    return mac.to_s
end

status = "closed"
present = []

# Read list of MACs from file

if File.file?(MACS)
    File.open(MACS, "r").each_line do |line|
        mac = filter_mac(line)
        present.push(mac) if mac.length > 0
    end
else
    exit "error reading file: #{MACS}"
end
# Read MAC addresses in the network
macs = get_macs
# clean the 'macs' 
# Compare addresses, if at least one matches, send
# the status as open to the server, else, send it as
# closed.

unless (macs & present).empty?
    status = "open"
end

http = Net::HTTP.new(SERVER, PORT)
req = Net::HTTP::Post.new("/status")
req.set_form_data({"status" => status})

res = http.request(req)

