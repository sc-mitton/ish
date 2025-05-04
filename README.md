
# Notes on WebRTC peer-to-peer connection process

## Signaling

### Sending Offer and Receiving Answer

The issue that needs to be delt with during this step is when the user that is trying to be reached is offline. In that case we can alert the user via a push notification, which after tapping it, will
take them to the app.

Steps:
1. Initiator taps a button to start a fight, or they enter a "room" where a fight is scheduled, or they do something that triggers the client to open a web socket connection with the server.
2. Simulatenous to step 1, open a supabase broadcast channel with a generated fight id
3. Send a message over the connection to the server for who you're trying to connect to (user id) along with a fight id (eventual id of the supabase broadcast channel).
4. If the user is online, return a message indicating that, otherwise send a push notification to the user (include the fight id in the push notification)
5. If the user doesn't acknowledge the push notification within a certain amount of time, the server sends back a message saying that the user is unreachable and closes the web socket connection
6. If the user does acknowledge the notification then their app is opened
7. Once the app is opened, it connects to the supabse broadcast channel and notifies the other user that they're connected
8. Now the user that initiated everythin can close the websocket connection with the server
9. Initiator sends the offer over the broadcast channel
10. Receiver receives the offer and returns the answer back over the channel

## Connecting

## Securing

## Communicating
