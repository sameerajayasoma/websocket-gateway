# WebSocket Gateway Written in Ballerina
Ballerina is a programming language designed for integrations. It makes it easy to write resilient services that integrate and communicate seamlessly. This repository contains a sample WebSocket gateway implemented in Ballerina. The gateway acts as a middleman between clients and backend services.

- [ws-gateway](./ws-gateway/main.bal) - WebSocket gateway package
- [backend-abc](./backend-abc/main.bal) - Backend WebSocket service named ABC
- [backend-pqr](./backend-pqr/main.bal) - Backend WebSocket service named PQR
- [backend-xyz](./backend-xyz/main.bal) - Backend WebSocket service named XYZ
- [client](./client/main.bal) - Sample WebSocket client. Can connect to any one of the backends based on configuration.

## Backend Service Discovery
Currently, backend service URLs are hard-coded within the WebSocket gateway using Ballerina configurable variables for simplicity in this example. Refer to the [Config.toml](./ws-gateway/Config.toml) for more details. While this sample uses static URLs, enhancements can be made to allow the gateway to discover backend services dynamically.

## Gateway Routing Behaviour 
The gateway determines the backend to connect with based on the ID HTTP header present in the WebSocket upgrade request initiated by the client. Valid ID header values include "Backend_ABC", "Backend_PQR", and "Backend_XYZ". The sample client is set up to send this header.

## WSS and Self-signed JWT
The sample client and the gateway uses the WSS protocol. Gateway and backend services uses WS protocol. Additionaly, gateway and client uses self-signed JWT for authentication. 

## Running the sample 

### Step 1: Set up the workspace
Install [Ballerina Swan Lake](https://ballerina.io/downloads/) and the [Ballerina extension](https://marketplace.visualstudio.com/items?itemName=wso2.ballerina) on VS Code.

### Step 2: (Optional) Open in VSCode
To explore the code more conveniently, consider opening this project directory in VSCode:

```bash
cd <this project directory>
code .
```

### Step 3: Start the Backend Services
Each backend service should be started in its own terminal tab. Here's how to start the ABC backend:

```sh
cd backend-abc
bal run
```

Repeat the above instructions for the PQR and XYZ backends.

### Step 4: Start the Gateway
In a new terminal, start the gateway with:

```sh
cd ws-gateway
bal run
```

### Step 5: Run the Client
With everything set up, you can now run the client. It's designed to connect to any of the backends based on your configuration.

For instance, to connect to the ABC backend:

```sh
cd client
bal run -- Backend_ABC
```

Similarly, to connect to the PQR or XYZ backends:

```sh
cd client
bal run -- Backend_PQR
```
```sh
cd client
bal run -- Backend_XYZ
```

## Next Steps
After running the sample, consider exploring deeper customizations or expanding on the base implementation. If you encounter any issues or have questions, feel free to open an issue on this repository.