# Hackerspace API handler

## idevices Push API endpoints

We define the methods to interact with the idevices (iPhone, iPad) with
the PushAPI handled by Apple servers, we use PUT, GET, POST and DELETE for 
managing the services that are register to be checked and anounced.

The Authentication its done via HTTPs Basic Auth and should be used in
combination with TLS. A second version is planned with better auth
support.

### GET /idevice

This provides some stadistics about the idevices handled by this
servers and some status info.

### GET /idevice/{TOKEN}

Returns a JSON document with an object describing the services handled for
the device identified by the token provided.

### PUT /idevice/{TOKEN}

It takes a JSON object as a document with the notifications to be added to
the iDevice identified by the token. The object can be empty.

	PUT /idevice/{Token}

	{
		'spaceapi': [ 
			"http://acemonstertoys.org/status.json",
			"https://ackspace.nl/status.php",
			"http://status.kreativitaet-trifft-technik.de/status.json",
			"https://bitlair.nl/statejson.php"
			]
	}

### POST /idevice/{TOKEN}

Updates the info for the device identified by the token, can add or remove
services to be handlend by the server.


	POST /idevice/{Token}

	{
		'add': ["uri1", "uri2"],
		'del': ["uri3", "uri4"]
	}

### DELETE /idevice/{TOKEN}

Removes this token and its related information from our server.
