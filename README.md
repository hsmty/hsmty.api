# Hackerspace API handler

## SpaceAPI API

Middleware to generate the status.json for the hackerspace and also
mantains information about our events, current and future. Currently
uses basic auth for authentication.

### GET /status.json

Returns the SpaceAPI status file as described [here][1].

  [1]: http://spaceapi.net/

### POST /status

Updates the status of the hackerspace with a Open/Close notification,
sensor information or some other 'event' in the space, should contain
status={open,close} as form data to update the space's status.

### GET /status/events

List all the current and planned events in the hackerspace.

### POST /status/events

Adds an event to the calendar, returns an UUID for that event.

    POST /status/events
    
    type=Check-in&name=Harrison

### GET /status/happenings

List all the current and planned happenings in the hackerspace.

### POST /status/happenings

Adds a happenings to the calendar, returns the id.

    POST /status/happenings
    
    time=123456789&name=Fieston&cost=300

The time **must** be in the future.

## iDevices

We define the methods to interact with the idevices (iPhone, iPad) with
the PushAPI handled by Apple servers, we use PUT, GET, POST and DELETE for 
managing the services that are register to be checked and anounced.

The Authentication its done via HTTPs Basic Auth and should be used in
combination with TLS. A second version is planned with better auth
support.

The devices authenticate with a pair of UUID and key.

### GET /idevice

This provides some stadistics about the idevices handled by this
servers and some status info.

### GET /idevice/{TOKEN}

Returns a JSON document with an object describing the services handled for
the device identified by the token provided.

### PUT /idevice/{TOKEN}

It takes a JSON object as a document with the notifications to be added to
the iDevice identified by the token. The object should contain at least the
uuid property, the token should be provided by Apple's push API and the URIs
 **must** be registered with spaceapi.net .

	PUT /idevice/{Token}

	{
	'spaceapi': [ 
		"http://acemonstertoys.org/status.json",
		"https://ackspace.nl/status.php",
		"http://status.kreativitaet-trifft-technik.de/status.json",
		"https://bitlair.nl/statejson.php"
		]
	}

The server with respond with a 201 Created status code and a 'secret' that will 
be used to sign all future requests to the server. In case that the token fails
to be verified by the Apple notification server our server will respond with a
400 Bad Request code.

### POST /idevice/{TOKEN}

Updates the info for the device identified by the token, can add or remove
services to be handlend by the server.


	POST /idevice/{Token}

	{
        'spaceapi': {
		'add': ["uri1", "uri2"],
		'del': ["uri3", "uri4"]
		}
	}

This request must be signed using the secret key that was shared with the client.

### DELETE /idevice/{TOKEN}

Removes this token and its related information from our server.

This request must be signed using the secret key that was shared with the client.

### Signing requests

To sign a request it must include a HMAC signature in an HTTP header with the following
format:

	X-Content-HMAC: <hash algorithm> <base64 encoded signature>

Availible hash algorithms: SHA-1, SHA-256

## Web site manager

For now only regenerates the website from the github directory (this is all
configured in the web server, we only run the update.sh).

### GET /web/update?key={KEY}&user={NAME}

Updates the website if the user is allowed via his key, this is used to
allow the push notification from github to our webserver.
