import ballerina/io;
import ballerina/lang.runtime;
import ballerina/log;
import ballerina/websocket;

websocket:ClientAuthConfig auth = {
    username: "ballerina",
    issuer: "wso2",
    audience: ["ballerina", "ballerina.org", "ballerina.io"],
    keyId: "5a0b754-895f-4279-8843-b745e11a57e9",
    jwtId: "JlbmMiOiJBMTI4Q0JDLUhTMjU2In",
    customClaims: {"scp": "admin"},
    expTime: 3600,
    signatureConfig: {
        config: {
            keyFile: "../resources/private.key"
        }
    }
};

websocket:ClientSecureSocket secureSocket = {
    cert: "../resources/public.crt"
};

type RequestMessage record {
    string id;
    string name;
    string email;
    string phone;
    string dob;
};

public function main(string backend = "Backend_ABC") returns error? {
    websocket:Client abcClient = check new ("wss://localhost:9090/gateway",
        customHeaders = {ID: backend}, readTimeout = 30, writeTimeout = 30,
        auth = auth, secureSocket = secureSocket
    );

    // Spawn two concurrent tasks to read and write messages to the backend.
    future<error> f1 = start readMessagesFromBackend(abcClient, backend);
    future<error> f2 = start sendMessageToBackend(abcClient, backend);

    // Wait for both the futures to complete. They complete only if an error occurs.
    map<error> errors = wait {f1, f2};
    io:println("Error occured while reading or writing to backend: ", errors);
}

// Read messages from the given backend.
function readMessagesFromBackend(websocket:Client chatClient, string backendId) returns error {
    while true {
        anydata|websocket:Error message = chatClient->readMessage();
        if message is websocket:Error {
            log:printError("Error occured while writing to backend 1: ", 'error = message, backendId = backendId);
            return message;
        } else {
            io:println(string `${backendId} >> Client: ${message.toString()}`);
        }
    }
}

// Send messages to the given backend in 5 second intervals.
function sendMessageToBackend(websocket:Client backendClient, string backendId) returns error {
    while true {
        RequestMessage payload = {id: "1", name: "John Doe", email: "doe@john.ai", phone: "123-456-7890", dob: "05/29/2003"};
        io:println(string `Client >> ${backendId}: ${payload.toString()}`);
        websocket:Error? status = backendClient->writeMessage(payload);
        if status is websocket:Error {
            log:printError("Error writing the message to backend", 'error = status, backendId = backendId);
            return status;
        }
        runtime:sleep(5);
    }
}

