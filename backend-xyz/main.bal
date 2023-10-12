import ballerina/lang.runtime;
import ballerina/log;
import ballerina/websocket;

type RequestMessage record {
    string id;
    string name;
    string email;
    string phone;
    string dob;
};

isolated service /backend on new websocket:Listener(8083) {

    isolated resource function get xyz() returns websocket:Service {
        // Accept the WebSocket upgrade by returning a `websocket:Service`.
        return new XYZService();
    }
}

isolated service class XYZService {
    *websocket:Service;

    isolated remote function onOpen(websocket:Caller caller) returns error? {
        log:printInfo("[XYZ Backend] Connection established", connectionId = caller.getConnectionId());
        _ = start self.writeToClient(caller);
    }

    remote function onClose(websocket:Caller caller, int statusCode, string reason) {
        log:printInfo("[XYZ Backend] Closing the connection", statusCode = statusCode, reason = reason, connectionId = caller.getConnectionId());
    }

    // This `remote function` is triggered when a new message is received
    // from a client. It accepts `anydata` as the function argument. The received data 
    // will be converted to the data type stated as the function argument.
    isolated remote function onMessage(websocket:Caller caller, RequestMessage payload) returns error? {
        log:printInfo("[XYZ Backend] Received message from client: ", payload = payload, connectionId = caller.getConnectionId());
    }

    isolated function writeToClient(websocket:Caller caller) {
        while true {
            if !caller.isOpen() {
                log:printInfo("[XYZ Backend] Connection is already closed", connectionId = caller.getConnectionId());
                return;
            }
            websocket:Error? status = caller->writeMessage({message: "Hello from XYZ Backend"});
            if status is websocket:Error {
                log:printError("[XYZ Backend] Error writing the message to client", 'error = status, connectionId = caller.getConnectionId());
                return;
            }
            runtime:sleep(2);
        }
    }
}
