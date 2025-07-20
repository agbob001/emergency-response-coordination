;; Emergency Response Coordination Smart Contract
;; A blockchain-based disaster relief and resource allocation system

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-unauthorized (err u102))
(define-constant err-invalid-amount (err u103))
(define-constant err-insufficient-funds (err u104))
(define-constant err-already-exists (err u105))
(define-constant err-invalid-status (err u106))

;; Data Variables
(define-data-var emergency-counter uint u0)
(define-data-var resource-counter uint u0)
(define-data-var organization-counter uint u0)

;; Data Maps
(define-map emergencies 
    { emergency-id: uint }
    {
        creator: principal,
        title: (string-ascii 100),
        description: (string-ascii 500),
        location: (string-ascii 100),
        severity: uint,
        status: (string-ascii 20),
        funds-needed: uint,
        funds-raised: uint,
        created-at: uint,
        updated-at: uint
    }
)

(define-map resources
    { resource-id: uint }
    {
        emergency-id: uint,
        resource-type: (string-ascii 50),
        quantity: uint,
        unit: (string-ascii 20),
        provider: principal,
        allocated: bool,
        created-at: uint
    }
)

(define-map organizations
    { org-id: uint }
    {
        name: (string-ascii 100),
        contact: (string-ascii 100),
        verified: bool,
        reputation-score: uint,
        admin: principal,
        created-at: uint
    }
)

(define-map emergency-donations
    { emergency-id: uint, donor: principal }
    { amount: uint, donated-at: uint }
)

(define-map resource-allocations
    { allocation-id: uint }
    {
        emergency-id: uint,
        resource-id: uint,
        quantity-allocated: uint,
        allocated-by: principal,
        allocated-at: uint,
        status: (string-ascii 20)
    }
)

(define-data-var allocation-counter uint u0)

;; Emergency Management Functions

(define-public (create-emergency 
    (title (string-ascii 100))
    (description (string-ascii 500))
    (location (string-ascii 100))
    (severity uint)
    (funds-needed uint))
    (let
        ((emergency-id (+ (var-get emergency-counter) u1)))
        (asserts! (and (> severity u0) (<= severity u5)) err-invalid-amount)
        (asserts! (> funds-needed u0) err-invalid-amount)
        
        (map-set emergencies
            { emergency-id: emergency-id }
            {
                creator: tx-sender,
                title: title,
                description: description,
                location: location,
                severity: severity,
                status: "active",
                funds-needed: funds-needed,
                funds-raised: u0,
                created-at: block-height,
                updated-at: block-height
            }
        )
        (var-set emergency-counter emergency-id)
        (ok emergency-id)
    )
)

(define-public (update-emergency-status (emergency-id uint) (new-status (string-ascii 20)))
    (let
        ((emergency (unwrap! (map-get? emergencies { emergency-id: emergency-id }) err-not-found)))
        (asserts! (is-eq tx-sender (get creator emergency)) err-unauthorized)
        (map-set emergencies
            { emergency-id: emergency-id }
            (merge emergency { status: new-status, updated-at: block-height })
        )
        (ok true)
    )
)

(define-read-only (get-emergency (emergency-id uint))
    (map-get? emergencies { emergency-id: emergency-id })
)

(define-read-only (get-emergency-count)
    (var-get emergency-counter)
)

;; Donation Functions

(define-public (donate-to-emergency (emergency-id uint))
    (let
        ((emergency (unwrap! (map-get? emergencies { emergency-id: emergency-id }) err-not-found))
         (donation-amount (stx-get-balance tx-sender)))
        (asserts! (> donation-amount u0) err-insufficient-funds)
        (asserts! (is-eq (get status emergency) "active") err-invalid-status)
        
        (try! (stx-transfer? donation-amount tx-sender (as-contract tx-sender)))
        
        (map-set emergency-donations
            { emergency-id: emergency-id, donor: tx-sender }
            { amount: donation-amount, donated-at: block-height }
        )
        
        (map-set emergencies
            { emergency-id: emergency-id }
            (merge emergency 
                { 
                    funds-raised: (+ (get funds-raised emergency) donation-amount),
                    updated-at: block-height
                }
            )
        )
        (ok donation-amount)
    )
)

(define-read-only (get-donation (emergency-id uint) (donor principal))
    (map-get? emergency-donations { emergency-id: emergency-id, donor: donor })
)

;; Resource Management Functions

(define-public (add-resource
    (emergency-id uint)
    (resource-type (string-ascii 50))
    (quantity uint)
    (unit (string-ascii 20)))
    (let
        ((resource-id (+ (var-get resource-counter) u1))
         (emergency (unwrap! (map-get? emergencies { emergency-id: emergency-id }) err-not-found)))
        (asserts! (> quantity u0) err-invalid-amount)
        (asserts! (is-eq (get status emergency) "active") err-invalid-status)
        
        (map-set resources
            { resource-id: resource-id }
            {
                emergency-id: emergency-id,
                resource-type: resource-type,
                quantity: quantity,
                unit: unit,
                provider: tx-sender,
                allocated: false,
                created-at: block-height
            }
        )
        (var-set resource-counter resource-id)
        (ok resource-id)
    )
)

(define-public (allocate-resource (resource-id uint) (quantity-to-allocate uint))
    (let
        ((resource (unwrap! (map-get? resources { resource-id: resource-id }) err-not-found))
         (allocation-id (+ (var-get allocation-counter) u1)))
        (asserts! (<= quantity-to-allocate (get quantity resource)) err-invalid-amount)
        (asserts! (not (get allocated resource)) err-invalid-status)
        
        (map-set resource-allocations
            { allocation-id: allocation-id }
            {
                emergency-id: (get emergency-id resource),
                resource-id: resource-id,
                quantity-allocated: quantity-to-allocate,
                allocated-by: tx-sender,
                allocated-at: block-height,
                status: "allocated"
            }
        )
        
        (map-set resources
            { resource-id: resource-id }
            (merge resource { allocated: true })
        )
        
        (var-set allocation-counter allocation-id)
        (ok allocation-id)
    )
)

(define-read-only (get-resource (resource-id uint))
    (map-get? resources { resource-id: resource-id })
)

(define-read-only (get-allocation (allocation-id uint))
    (map-get? resource-allocations { allocation-id: allocation-id })
)

;; Organization Management Functions

(define-public (register-organization
    (name (string-ascii 100))
    (contact (string-ascii 100)))
    (let
        ((org-id (+ (var-get organization-counter) u1)))
        (map-set organizations
            { org-id: org-id }
            {
                name: name,
                contact: contact,
                verified: false,
                reputation-score: u0,
                admin: tx-sender,
                created-at: block-height
            }
        )
        (var-set organization-counter org-id)
        (ok org-id)
    )
)

(define-public (verify-organization (org-id uint))
    (let
        ((organization (unwrap! (map-get? organizations { org-id: org-id }) err-not-found)))
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (map-set organizations
            { org-id: org-id }
            (merge organization { verified: true })
        )
        (ok true)
    )
)

(define-public (update-reputation (org-id uint) (new-score uint))
    (let
        ((organization (unwrap! (map-get? organizations { org-id: org-id }) err-not-found)))
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (map-set organizations
            { org-id: org-id }
            (merge organization { reputation-score: new-score })
        )
        (ok true)
    )
)

(define-read-only (get-organization (org-id uint))
    (map-get? organizations { org-id: org-id })
)

;; Fund Distribution Functions

(define-public (distribute-funds (emergency-id uint) (recipient principal) (amount uint))
    (let
        ((emergency (unwrap! (map-get? emergencies { emergency-id: emergency-id }) err-not-found)))
        (asserts! (is-eq tx-sender (get creator emergency)) err-unauthorized)
        (asserts! (<= amount (get funds-raised emergency)) err-insufficient-funds)
        (asserts! (> amount u0) err-invalid-amount)
        
        (try! (as-contract (stx-transfer? amount tx-sender recipient)))
        
        (map-set emergencies
            { emergency-id: emergency-id }
            (merge emergency 
                { 
                    funds-raised: (- (get funds-raised emergency) amount),
                    updated-at: block-height
                }
            )
        )
        (ok true)
    )
)

;; Emergency Response Analytics

(define-read-only (get-emergency-statistics (emergency-id uint))
    (let
        ((emergency (unwrap! (map-get? emergencies { emergency-id: emergency-id }) err-not-found)))
        (ok {
            emergency-id: emergency-id,
            title: (get title emergency),
            status: (get status emergency),
            severity: (get severity emergency),
            funds-needed: (get funds-needed emergency),
            funds-raised: (get funds-raised emergency),
            funding-percentage: (/ (* (get funds-raised emergency) u100) (get funds-needed emergency)),
            created-at: (get created-at emergency),
            updated-at: (get updated-at emergency)
        })
    )
)

;; Contract Management

(define-public (withdraw-contract-balance (amount uint))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (as-contract (stx-transfer? amount tx-sender contract-owner))
    )
)

(define-read-only (get-contract-balance)
    (stx-get-balance (as-contract tx-sender))
)

;; Initialize contract
(begin
    (var-set emergency-counter u0)
    (var-set resource-counter u0)
    (var-set organization-counter u0)
    (var-set allocation-counter u0)
)
;; Development branch - Emergency Response Coordination v1.0
