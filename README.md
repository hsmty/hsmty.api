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

## Web site manager

For now only regenerates the website from the github directory (this is all
configured in the web server, we only run the update.sh).

### GET /web/update?key={KEY}&user={NAME}

Updates the website if the user is allowed via his key, this is used to
allow the push notification from github to our webserver.
