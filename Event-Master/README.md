# Decentralized Community Event Management Platform

A comprehensive blockchain-based event management system built on Stacks that enables decentralized event organization with transparent registration, automated payments, capacity management, and trustless coordination for community gatherings.

## Features

- **Decentralized Event Creation**: Create and manage events without intermediaries
- **Automated Registration**: Seamless participant registration with capacity limits
- **Integrated Payment Processing**: Built-in STX payment handling for paid events
- **Transparent Attendance Tracking**: Real-time participant count monitoring
- **Permission-Based Administration**: Secure event management controls
- **Real-Time Status Monitoring**: Live event status and availability tracking


## Architecture

The smart contract is built using Clarity smart contract language for the Stacks blockchain. It consists of:

### Data Structures
- **Event Registry**: Stores comprehensive event information
- **Participant Registry**: Tracks user registrations
- **Attendance Counter**: Maintains real-time participant counts

### Core Components
- **Event Management**: Create, update, activate/deactivate events
- **Registration System**: Handle participant registration and payments
- **Query Interface**: Read-only functions for data retrieval
- **Validation Layer**: Comprehensive input validation and security checks

## Installation

### Prerequisites
- Stacks CLI installed
- Clarinet development environment
- Access to Stacks testnet or mainnet

## Usage

### Creating an Event

```clarity
(contract-call? .event-management create-event
    "Community Meetup"
    "Monthly developer meetup to discuss blockchain technology"
    "Tech Hub Downtown"
    u1735689600  ;; Unix timestamp
    u50          ;; Max participants
    u1000000     ;; Entry fee in micro-STX (1 STX)
)
```

### Registering for an Event

```clarity
(contract-call? .event-management register-for-event u0)
```

### Checking Event Information

```clarity
(contract-call? .event-management get-event-info u0)
```

## Functions

### Public Functions

#### Event Management
- `create-event`: Create a new community event
- `update-event`: Update existing event details (organizer only)
- `deactivate-event`: Deactivate an event (organizer only)
- `reactivate-event`: Reactivate an event (organizer only)

#### Registration Management
- `register-for-event`: Register as a participant
- `unregister-from-event`: Cancel registration

### Read-Only Functions

#### Event Information
- `get-event-info`: Get complete event details
- `get-event-stats`: Get event statistics and status
- `get-total-events`: Get total number of events created
- `event-exists`: Check if an event exists
- `is-event-active`: Check if an event is active

#### Participant Information
- `is-participant-registered`: Check registration status
- `get-attendance-count`: Get current participant count
- `get-available-spots`: Get remaining spots
- `is-organizer`: Check if user is event organizer

## Error Codes

| Code | Constant | Description |
|------|----------|-------------|
| 100 | ERR-EVENT-NOT-FOUND | Event does not exist |
| 101 | ERR-UNAUTHORIZED-ACCESS | User not authorized for this action |
| 102 | ERR-EVENT-ALREADY-EXISTS | Event already exists |
| 103 | ERR-CAPACITY-EXCEEDED | Event has reached maximum capacity |
| 104 | ERR-ALREADY-REGISTERED | User already registered for event |
| 105 | ERR-PAYMENT-FAILED | Payment processing failed |
| 106 | ERR-EVENT-INACTIVE | Event is not active |
| 107 | ERR-INVALID-TITLE | Invalid event title |
| 108 | ERR-INVALID-DESCRIPTION | Invalid event description |
| 109 | ERR-INVALID-LOCATION | Invalid event location |
| 110 | ERR-INVALID-TIMESTAMP | Invalid event timestamp |
| 111 | ERR-INVALID-CAPACITY | Invalid capacity (must be 1-1000) |
| 112 | ERR-INVALID-FEE | Invalid fee amount |
| 113 | ERR-INVALID-EVENT-ID | Invalid event ID |
| 114 | ERR-NOT-REGISTERED | User not registered for event |

## Configuration

### Capacity Limits
- **Minimum Participants**: 1
- **Maximum Participants**: 1000

### String Limits
- **Title**: 100 characters (ASCII)
- **Description**: 500 characters (ASCII)
- **Location**: 200 characters (ASCII)

### Validation Rules
- Event timestamps must be in the future
- Only event organizers can update/deactivate events
- Participants cannot register twice for the same event
- Events must have available capacity for new registrations

## Examples

### Complete Event Lifecycle

```clarity
;; 1. Create an event
(contract-call? .event-management create-event
    "Blockchain Workshop"
    "Learn about smart contract development"
    "Innovation Center"
    u1735689600
    u25
    u500000
)
;; Returns: (ok u0)

;; 2. Check event information
(contract-call? .event-management get-event-info u0)
;; Returns: Event details

;; 3. Register for the event
(contract-call? .event-management register-for-event u0)
;; Returns: (ok true)

;; 4. Check attendance
(contract-call? .event-management get-attendance-count u0)
;; Returns: (ok u1)

;; 5. Get event statistics
(contract-call? .event-management get-event-stats u0)
;; Returns: Complete stats object
```

### Event Management

```clarity
;; Update event details (organizer only)
(contract-call? .event-management update-event
    u0
    "Advanced Blockchain Workshop"
    "Deep dive into smart contract security"
    "Tech Campus"
    u1735689600
    u30
    u750000
)

;; Deactivate event temporarily
(contract-call? .event-management deactivate-event u0)

;; Reactivate event
(contract-call? .event-management reactivate-event u0)
```

### Development Guidelines
- Follow Clarity best practices
- Add comprehensive tests for new features
- Update documentation for any changes
- Ensure all tests pass before submitting

## Security Considerations

- **Payment Security**: All STX transfers are atomic and validated
- **Access Control**: Only event organizers can modify their events
- **Input Validation**: Comprehensive validation prevents invalid data
- **Reentrancy Protection**: State changes occur before external calls
- **Capacity Management**: Prevents overbooking through atomic operations