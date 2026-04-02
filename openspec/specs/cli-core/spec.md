## ADDED Requirements

### Requirement: CLI lists configured brokers
The CLI SHALL provide a `list` subcommand that prints all broker names configured in the macOS app's data store, one per line.

#### Scenario: List brokers
- **WHEN** user runs `mqtt-analyzer list`
- **THEN** the CLI prints each configured broker's alias, one per line, to stdout

#### Scenario: No brokers configured
- **WHEN** user runs `mqtt-analyzer list` and no brokers are configured
- **THEN** the CLI prints a message indicating no brokers are configured and exits with code 1

### Requirement: CLI selects broker by name
The CLI SHALL accept a `-s` / `--system` option that selects a broker by its alias name. This option is required for `subscribe` and `publish` subcommands.

#### Scenario: Valid broker selection
- **WHEN** user provides `-s "My Broker"` and a broker with alias "My Broker" exists
- **THEN** the CLI uses that broker's connection settings (host, port, auth, TLS, protocol version)

#### Scenario: Unknown broker name
- **WHEN** user provides `-s "Unknown"` and no broker with that alias exists
- **THEN** the CLI prints an error listing available broker names and exits with code 1

### Requirement: CLI subscribes to topics
The CLI SHALL provide a `subscribe` subcommand that connects to the selected broker, subscribes to one or more topic filters, and streams received messages to stdout.

#### Scenario: Subscribe to a single topic
- **WHEN** user runs `mqtt-analyzer -s "Broker" subscribe "home/temperature"`
- **THEN** the CLI connects, subscribes to `home/temperature`, and prints each incoming message as `<topic>\t<payload>` to stdout

#### Scenario: Subscribe to a wildcard topic
- **WHEN** user runs `mqtt-analyzer -s "Broker" subscribe "home/#"`
- **THEN** the CLI subscribes using the MQTT wildcard and prints all matching messages

#### Scenario: Subscribe with JSON output
- **WHEN** user runs `mqtt-analyzer -s "Broker" subscribe "home/#" --json`
- **THEN** each message is printed as a JSON object with fields: `topic`, `payload`, `qos`, `retain`, `timestamp`

#### Scenario: Subscribe with QoS
- **WHEN** user runs `mqtt-analyzer -s "Broker" subscribe "topic" --qos 2`
- **THEN** the CLI subscribes with QoS level 2

#### Scenario: Subscribe without topic argument
- **WHEN** user runs `mqtt-analyzer -s "Broker" subscribe` without a topic argument
- **THEN** the CLI subscribes to the broker's default configured subscriptions

### Requirement: CLI publishes messages
The CLI SHALL provide a `publish` subcommand that connects to the selected broker, publishes a message, and exits.

#### Scenario: Publish a message
- **WHEN** user runs `mqtt-analyzer -s "Broker" publish "home/light" "on"`
- **THEN** the CLI connects, publishes "on" to topic `home/light` with QoS 0, and exits with code 0

#### Scenario: Publish with QoS and retain
- **WHEN** user runs `mqtt-analyzer -s "Broker" publish "home/light" "on" --qos 1 --retain`
- **THEN** the CLI publishes with QoS 1 and the retain flag set

#### Scenario: Publish from stdin
- **WHEN** user runs `echo '{"temp": 22}' | mqtt-analyzer -s "Broker" publish "home/data" -`
- **THEN** the CLI reads the message payload from stdin and publishes it

### Requirement: CLI handles connection errors gracefully
The CLI SHALL print a meaningful error message and exit with a non-zero code when connection fails.

#### Scenario: Connection refused
- **WHEN** the broker is unreachable or refuses the connection
- **THEN** the CLI prints an error message including the hostname and port, and exits with code 1

#### Scenario: Authentication failure
- **WHEN** the broker rejects the credentials
- **THEN** the CLI prints an authentication error message and exits with code 1

### Requirement: CLI supports MQTT 3.1.1 and MQTT 5.0
The CLI SHALL respect the protocol version configured on the selected broker and use the corresponding MQTT client implementation.

#### Scenario: Connect with MQTT 5.0
- **WHEN** the selected broker is configured for MQTT 5.0
- **THEN** the CLI uses the MQTT 5.0 client for the connection

#### Scenario: Connect with MQTT 3.1.1
- **WHEN** the selected broker is configured for MQTT 3.1.1
- **THEN** the CLI uses the MQTT 3.1.1 client for the connection
