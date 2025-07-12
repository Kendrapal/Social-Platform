;; DECENTRALIZED COMMUNITY EVENT MANAGEMENT PLATFORM SMART CONTRACT
;;
;; A comprehensive blockchain-based event management system built on Stacks that enables
;; decentralized event organization with transparent registration, automated payments,
;; capacity management, and trustless coordination for community gatherings.
;; 
;; Core Features:
;; - Decentralized event creation and management
;; - Automated registration with capacity limits
;; - Integrated payment processing for paid events
;; - Transparent attendance tracking
;; - Permission-based event administration
;; - Real-time event status monitoring

;; GLOBAL STATE MANAGEMENT

;; Tracks the next available event identifier
(define-data-var next-event-id uint u0)

;; DATA STRUCTURES

;; Comprehensive event information storage
(define-map event-registry
    uint ;; event-id
    {
        event-organizer: principal,
        title: (string-ascii 100),
        description: (string-ascii 500),
        location: (string-ascii 200),
        event-timestamp: uint,
        max-participants: uint,
        entry-fee-micro-stx: uint,
        is-active: bool
    }
)

;; Participant registration tracking
(define-map participant-registry
    { event-id: uint, participant: principal }
    bool
)

;; Real-time attendance counter for each event
(define-map attendance-counter
    uint ;; event-id
    uint ;; current-participant-count
)

;; ERROR HANDLING CONSTANTS

(define-constant ERR-EVENT-NOT-FOUND u100)
(define-constant ERR-UNAUTHORIZED-ACCESS u101)
(define-constant ERR-EVENT-ALREADY-EXISTS u102)
(define-constant ERR-CAPACITY-EXCEEDED u103)
(define-constant ERR-ALREADY-REGISTERED u104)
(define-constant ERR-PAYMENT-FAILED u105)
(define-constant ERR-EVENT-INACTIVE u106)
(define-constant ERR-INVALID-TITLE u107)
(define-constant ERR-INVALID-DESCRIPTION u108)
(define-constant ERR-INVALID-LOCATION u109)
(define-constant ERR-INVALID-TIMESTAMP u110)
(define-constant ERR-INVALID-CAPACITY u111)
(define-constant ERR-INVALID-FEE u112)
(define-constant ERR-INVALID-EVENT-ID u113)
(define-constant ERR-NOT-REGISTERED u114)

;; CONFIGURATION CONSTANTS

(define-constant MIN-PARTICIPANT-CAPACITY u1)
(define-constant MAX-PARTICIPANT-CAPACITY u1000)

;; VALIDATION UTILITIES

;; Validates non-empty string input
(define-private (is-valid-string (input-string (string-ascii 500)))
    (> (len input-string) u0)
)

;; Checks if event ID exists in the system
(define-private (is-valid-event-id (event-id uint))
    (< event-id (var-get next-event-id))
)

;; Validates future timestamp
(define-private (is-future-timestamp (timestamp uint))
    (match (get-block-info? time u0)
        current-time (> timestamp current-time)
        false
    )
)

;; Validates capacity within acceptable limits
(define-private (is-valid-capacity (capacity uint))
    (and 
        (>= capacity MIN-PARTICIPANT-CAPACITY)
        (<= capacity MAX-PARTICIPANT-CAPACITY)
    )
)

;; Validates registration fee (currently accepts all values)
(define-private (is-valid-fee (fee-amount uint))
    true
)

;; Retrieves event data with validation
(define-private (get-event-data (event-id uint))
    (match (map-get? event-registry event-id)
        event-info (ok event-info)
        (err ERR-EVENT-NOT-FOUND)
    )
)

;; Checks if user is event organizer
(define-private (is-event-organizer (event-id uint) (user principal))
    (match (get-event-data event-id)
        ok-value (is-eq user (get event-organizer ok-value))
        err-value false
    )
)

;; Gets current participant count for an event
(define-private (get-participant-count (event-id uint))
    (default-to u0 (map-get? attendance-counter event-id))
)

;; EVENT MANAGEMENT FUNCTIONS

;; Creates a new community event with comprehensive validation
(define-public (create-event 
    (title (string-ascii 100))
    (description (string-ascii 500))
    (location (string-ascii 200))
    (event-timestamp uint)
    (max-participants uint)
    (entry-fee-micro-stx uint)
)
    (let 
        (
            (new-event-id (var-get next-event-id))
        )
        ;; Input validation
        (asserts! (is-valid-string title) (err ERR-INVALID-TITLE))
        (asserts! (is-valid-string description) (err ERR-INVALID-DESCRIPTION))
        (asserts! (is-valid-string location) (err ERR-INVALID-LOCATION))
        (asserts! (is-future-timestamp event-timestamp) (err ERR-INVALID-TIMESTAMP))
        (asserts! (is-valid-capacity max-participants) (err ERR-INVALID-CAPACITY))
        (asserts! (is-valid-fee entry-fee-micro-stx) (err ERR-INVALID-FEE))
        
        ;; Update event counter
        (var-set next-event-id (+ new-event-id u1))
        
        ;; Store event information
        (map-set event-registry new-event-id {
            event-organizer: tx-sender,
            title: title,
            description: description,
            location: location,
            event-timestamp: event-timestamp,
            max-participants: max-participants,
            entry-fee-micro-stx: entry-fee-micro-stx,
            is-active: true
        })
        
        ;; Initialize attendance counter
        (map-set attendance-counter new-event-id u0)
        
        (ok new-event-id)
    )
)

;; Updates existing event details (organizer only)
(define-public (update-event 
    (event-id uint)
    (title (string-ascii 100))
    (description (string-ascii 500))
    (location (string-ascii 200))
    (event-timestamp uint)
    (max-participants uint)
    (entry-fee-micro-stx uint)
)
    (let
        (
            (current-event (unwrap! (get-event-data event-id) (err ERR-EVENT-NOT-FOUND)))
            (current-participants (get-participant-count event-id))
        )
        ;; Validation checks
        (asserts! (is-valid-event-id event-id) (err ERR-INVALID-EVENT-ID))
        (asserts! (is-event-organizer event-id tx-sender) (err ERR-UNAUTHORIZED-ACCESS))
        (asserts! (is-valid-string title) (err ERR-INVALID-TITLE))
        (asserts! (is-valid-string description) (err ERR-INVALID-DESCRIPTION))
        (asserts! (is-valid-string location) (err ERR-INVALID-LOCATION))
        (asserts! (is-future-timestamp event-timestamp) (err ERR-INVALID-TIMESTAMP))
        (asserts! (is-valid-capacity max-participants) (err ERR-INVALID-CAPACITY))
        (asserts! (is-valid-fee entry-fee-micro-stx) (err ERR-INVALID-FEE))
        (asserts! (>= max-participants current-participants) (err ERR-CAPACITY-EXCEEDED))
        
        ;; Update event information
        (map-set event-registry event-id {
            event-organizer: (get event-organizer current-event),
            title: title,
            description: description,
            location: location,
            event-timestamp: event-timestamp,
            max-participants: max-participants,
            entry-fee-micro-stx: entry-fee-micro-stx,
            is-active: (get is-active current-event)
        })
        
        (ok true)
    )
)

;; Deactivates an event (organizer only)
(define-public (deactivate-event (event-id uint))
    (let
        (
            (current-event (unwrap! (get-event-data event-id) (err ERR-EVENT-NOT-FOUND)))
        )
        (asserts! (is-valid-event-id event-id) (err ERR-INVALID-EVENT-ID))
        (asserts! (is-event-organizer event-id tx-sender) (err ERR-UNAUTHORIZED-ACCESS))
        
        ;; Mark event as inactive
        (map-set event-registry event-id 
            (merge current-event { is-active: false })
        )
        
        (ok true)
    )
)

;; Reactivates an event (organizer only)
(define-public (reactivate-event (event-id uint))
    (let
        (
            (current-event (unwrap! (get-event-data event-id) (err ERR-EVENT-NOT-FOUND)))
        )
        (asserts! (is-valid-event-id event-id) (err ERR-INVALID-EVENT-ID))
        (asserts! (is-event-organizer event-id tx-sender) (err ERR-UNAUTHORIZED-ACCESS))
        
        ;; Mark event as active
        (map-set event-registry event-id 
            (merge current-event { is-active: true })
        )
        
        (ok true)
    )
)

;; PARTICIPANT REGISTRATION FUNCTIONS

;; Registers a participant for an event with payment processing
(define-public (register-for-event (event-id uint))
    (let 
        (
            (event-info (unwrap! (get-event-data event-id) (err ERR-EVENT-NOT-FOUND)))
            (current-participants (get-participant-count event-id))
            (registration-key { event-id: event-id, participant: tx-sender })
        )
        ;; Validation checks
        (asserts! (is-valid-event-id event-id) (err ERR-INVALID-EVENT-ID))
        (asserts! (get is-active event-info) (err ERR-EVENT-INACTIVE))
        (asserts! (< current-participants (get max-participants event-info)) (err ERR-CAPACITY-EXCEEDED))
        (asserts! (is-none (map-get? participant-registry registration-key)) (err ERR-ALREADY-REGISTERED))
        
        ;; Process payment if required
        (if (> (get entry-fee-micro-stx event-info) u0)
            (unwrap! (stx-transfer? (get entry-fee-micro-stx event-info) tx-sender (get event-organizer event-info)) 
                     (err ERR-PAYMENT-FAILED))
            true
        )
        
        ;; Complete registration
        (map-set participant-registry registration-key true)
        (map-set attendance-counter event-id (+ current-participants u1))
        
        (ok true)
    )
)

;; Unregisters a participant from an event
(define-public (unregister-from-event (event-id uint))
    (let
        (
            (event-info (unwrap! (get-event-data event-id) (err ERR-EVENT-NOT-FOUND)))
            (registration-key { event-id: event-id, participant: tx-sender })
            (current-participants (get-participant-count event-id))
        )
        ;; Validation checks
        (asserts! (is-valid-event-id event-id) (err ERR-INVALID-EVENT-ID))
        (asserts! (is-some (map-get? participant-registry registration-key)) (err ERR-NOT-REGISTERED))
        (asserts! (> current-participants u0) (err ERR-EVENT-NOT-FOUND))
        
        ;; Remove registration
        (map-delete participant-registry registration-key)
        (map-set attendance-counter event-id (- current-participants u1))
        
        ;; Note: Refund functionality not implemented in this version
        (ok true)
    )
)

;; READ-ONLY QUERY FUNCTIONS

;; Retrieves complete event information
(define-read-only (get-event-info (event-id uint))
    (begin
        (asserts! (is-valid-event-id event-id) (err ERR-INVALID-EVENT-ID))
        (get-event-data event-id)
    )
)

;; Checks if a participant is registered for an event
(define-read-only (is-participant-registered (event-id uint) (participant principal))
    (begin
        (asserts! (is-valid-event-id event-id) (err ERR-INVALID-EVENT-ID))
        (ok (default-to false 
            (map-get? participant-registry { event-id: event-id, participant: participant })
        ))
    )
)

;; Gets current number of registered participants
(define-read-only (get-attendance-count (event-id uint))
    (begin
        (asserts! (is-valid-event-id event-id) (err ERR-INVALID-EVENT-ID))
        (ok (get-participant-count event-id))
    )
)

;; Checks if a principal is the event organizer
(define-read-only (is-organizer (event-id uint) (organizer principal))
    (begin
        (asserts! (is-valid-event-id event-id) (err ERR-INVALID-EVENT-ID))
        (ok (is-event-organizer event-id organizer))
    )
)

;; Checks if an event is currently active
(define-read-only (is-event-active (event-id uint))
    (begin
        (asserts! (is-valid-event-id event-id) (err ERR-INVALID-EVENT-ID))
        (match (map-get? event-registry event-id)
            event-info (ok (get is-active event-info))
            (err ERR-EVENT-NOT-FOUND)
        )
    )
)

;; Verifies if an event exists
(define-read-only (event-exists (event-id uint))
    (begin
        (asserts! (is-valid-event-id event-id) (err ERR-INVALID-EVENT-ID))
        (ok (is-some (map-get? event-registry event-id)))
    )
)

;; Gets available spots for an event
(define-read-only (get-available-spots (event-id uint))
    (begin
        (asserts! (is-valid-event-id event-id) (err ERR-INVALID-EVENT-ID))
        (match (map-get? event-registry event-id)
            event-info 
            (ok (- (get max-participants event-info) (get-participant-count event-id)))
            (err ERR-EVENT-NOT-FOUND)
        )
    )
)

;; Gets the total number of events created
(define-read-only (get-total-events)
    (ok (var-get next-event-id))
)

;; Gets event registration statistics
(define-read-only (get-event-stats (event-id uint))
    (begin
        (asserts! (is-valid-event-id event-id) (err ERR-INVALID-EVENT-ID))
        (match (map-get? event-registry event-id)
            event-info 
            (let
                (
                    (current-participants (get-participant-count event-id))
                    (max-capacity (get max-participants event-info))
                )
                (ok {
                    current-participants: current-participants,
                    max-participants: max-capacity,
                    available-spots: (- max-capacity current-participants),
                    is-full: (is-eq current-participants max-capacity),
                    is-active: (get is-active event-info)
                })
            )
            (err ERR-EVENT-NOT-FOUND)
        )
    )
)