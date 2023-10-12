import ballerina/http;
import ballerina/log;
import ballerina/websocket;

// Values for these configurations are provided when running the service.
// See the Config.toml file in the root directory.
configurable map<string> backends = ?;
configurable int port = ?;

# This service accepts the WebSocket upgrade request.
isolated service /gateway on new websocket:Listener(port) {

    # Description.
    #
    # + id - parameter description
    # + return - return value description
    isolated resource function get .(@http:Header {name: "ID"} string id) returns websocket:Service|websocket:UpgradeError {
        log:printInfo("WebSocket handshake happened! ", backendId = id);
        if !backends.hasKey(id) {
            return <websocket:UpgradeError>error("Invalid service identifier");
        }

        string backendUrl = backends.get(id);
        websocket:Service|error router = new Router(id, backendUrl);
        if router is error {
            return <websocket:UpgradeError>error(router.message());
        } else {
            return router;
        }
    }
}

isolated service class Router {
    *websocket:Service;
    private final websocket:Client wsBackend;
    private final string backendId;

    # Router service initializer that creates the WebSocket client to the backend.
    #
    # + backendId - backend identifier
    # + backendUrl - backend URL
    # + return - return value description
    isolated function init(string backendId, string backendUrl) returns error? {
        self.backendId = backendId;
        self.wsBackend = check new websocket:Client(backendUrl, readTimeout = 30, writeTimeout = 30);
    }

    # As soon as the WebSocket handshake is completed and the connection is established, 
    # the onOpen remote method is dispatched.
    #
    # + caller - represents the client who initiated the connection
    # + return - returns and error if the connection to the backend fails 
    isolated remote function onOpen(websocket:Caller caller) returns error? {
        log:printInfo("Connection established with the backend", backendId = self.backendId, connectionId = caller.getConnectionId());
        _ = start self.routeMessagesFromBackendToClient(self.wsBackend, caller);
    }

    # This remote method is dispatched when a close frame with a statusCode and a reason is received
    #
    # + caller - represents the client who initiated the connection  
    # + statusCode - statusCode  
    # + reason - reason
    isolated remote function onClose(websocket:Caller caller, int statusCode, string reason) {
        log:printInfo("Connection closed by the client", 'statusCode = statusCode, 'reason = reason, backendId = self.backendId, connectionId = caller.getConnectionId());
        websocket:Error? status = self.wsBackend->close(reason = "Client closed the connection");
        if status is websocket:Error {
            self.logError("Error closing the backend connection", status, caller);
        }
    }

    # This `remote function` is triggered when a new message is received from a client. It accepts `anydata` as the function argument. The received data will be converted to the data type stated as the function argument..
    #
    # + caller - represents the client who initiated the message  
    # + message - message received from the client
    # + return - return an error if the message cannot be written to the backend
    isolated remote function onMessage(websocket:Caller caller, anydata message) returns error? {
        websocket:Error? status = self.wsBackend->writeMessage(message);
        if status is websocket:ConnectionError {
            self.logError("Backend connection is closed", status, caller);
            websocket:Error? closeErr = caller->close(statusCode = 1000, reason = "Backend connection is closed");
            if closeErr is websocket:Error {
                self.logError("Error closing the client connection", closeErr, caller);
            }
        } else if status is websocket:Error {
            self.logError("Error writing message to the backend", status, caller);

        }
    }

    # Routes messages received from the backend to the client.
    #
    # + wsBackend - websocket client to the backend  
    # + wsCaller - represents the client who initiated the connection
    isolated function routeMessagesFromBackendToClient(websocket:Client wsBackend, websocket:Caller wsCaller) {
        while (true) {
            anydata|websocket:Error msg = self.wsBackend->readMessage();
            if msg is websocket:Error {
                self.logError("Error reading message from the backend", msg, wsCaller);
                return;
            } else {
                websocket:Error? err = wsCaller->writeMessage(msg);
                if err is websocket:Error {
                    self.logError("Error writing message to client", err, wsCaller);
                    return;
                }
            }
        }
    }

    isolated function logError(string msg, websocket:Error err, websocket:Caller caller) {
        log:printError(msg, 'error = err, backendId = self.backendId, connectionId = caller.getConnectionId());
    }
}
