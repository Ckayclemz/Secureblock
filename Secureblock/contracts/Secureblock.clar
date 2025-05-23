;; Secureblock Smart Contract
;; Manages decentralized donations and secure fund distribution for verified recipients

;; Error Constants
(define-constant ERR-UNAUTHORIZED (err u100))
(define-constant ERR-BENEFICIARY-EXISTS (err u101))
(define-constant ERR-BENEFICIARY-NOT-FOUND (err u102))
(define-constant ERR-INSUFFICIENT-TREASURY-FUNDS (err u103))
(define-constant ERR-CONTRIBUTION-TOO-SMALL (err u104))
(define-constant ERR-TREASURY-INACTIVE (err u105))
(define-constant ERR-INVALID-VALUE (err u106))
(define-constant ERR-INVALID-STATE (err u107))
(define-constant ERR-INVALID-ADMIN (err u108))

;; Data Variables
(define-data-var treasury-admin principal tx-sender)
(define-data-var treasury-balance uint u0)
(define-data-var treasury-operational bool true)
(define-data-var treasury-min-contribution uint u1000000) ;; 1 STX
(define-data-var treasury-emergency-mode bool false)

;; Data Maps
(define-map beneficiaries 
    principal 
    {
        is-eligible: bool,
        total-disbursed: uint,
        last-disbursement-block: uint,
        current-state: (string-ascii 20)
    }
)

(define-map donors
    principal
    {
        total-donation: uint,
        last-donation-block: uint
    }
)

;; Read-only functions
(define-read-only (get-admin)
    (var-get treasury-admin)
)

(define-read-only (get-treasury-balance)
    (var-get treasury-balance)
)

(define-read-only (get-beneficiary-data (entity principal))
    (map-get? beneficiaries entity)
)

(define-read-only (get-donor-data (entity principal))
    (map-get? donors entity)
)

(define-read-only (is-treasury-active)
    (and (var-get treasury-operational) (not (var-get treasury-emergency-mode)))
)

;; Private functions
(define-private (is-admin)
    (is-eq tx-sender (var-get treasury-admin))
)

(define-private (update-donor-record (entity principal) (amount uint))
    (let (
        (existing (default-to 
            { total-donation: u0, last-donation-block: u0 } 
            (map-get? donors entity)
        ))
    )
    (map-set donors
        entity
        {
            total-donation: (+ (get total-donation existing) amount),
            last-donation-block: stacks-block-height
        }
    ))
)

;; Validation helpers
(define-private (is-valid-value (value uint))
    (and 
        (> value u0)
        (<= value u1000000000000)
    )
)

(define-private (is-valid-state (state (string-ascii 20)))
    (or 
        (is-eq state "active")
        (is-eq state "pending")
        (is-eq state "suspended")
        (is-eq state "completed")
    )
)

(define-private (is-valid-admin (entity principal))
    (and 
        (not (is-eq entity (var-get treasury-admin)))
        (not (is-eq entity (as-contract tx-sender)))
    )
)

;; Public functions
(define-public (donate)
    (let ((amount (stx-get-balance tx-sender)))
        (asserts! (>= amount (var-get treasury-min-contribution)) ERR-CONTRIBUTION-TOO-SMALL)
        (asserts! (is-treasury-active) ERR-TREASURY-INACTIVE)

        (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
        (var-set treasury-balance (+ (var-get treasury-balance) amount))
        (update-donor-record tx-sender amount)
        (ok amount)
    )
)

(define-public (register-beneficiary (entity principal))
    (begin
        (asserts! (is-admin) ERR-UNAUTHORIZED)
        (asserts! (is-none (map-get? beneficiaries entity)) ERR-BENEFICIARY-EXISTS)
        
        (map-set beneficiaries 
            entity
            {
                is-eligible: true,
                total-disbursed: u0,
                last-disbursement-block: u0,
                current-state: "active"
            }
        )
        (ok true)
    )
)

(define-public (disburse-funds (entity principal) (amount uint))
    (begin
        (asserts! (is-admin) ERR-UNAUTHORIZED)
        (asserts! (is-treasury-active) ERR-TREASURY-INACTIVE)
        (asserts! (>= (var-get treasury-balance) amount) ERR-INSUFFICIENT-TREASURY-FUNDS)
        (asserts! (is-some (map-get? beneficiaries entity)) ERR-BENEFICIARY-NOT-FOUND)

        (try! (as-contract (stx-transfer? amount tx-sender entity)))
        (var-set treasury-balance (- (var-get treasury-balance) amount))

        (let (
            (record (unwrap! (map-get? beneficiaries entity) ERR-BENEFICIARY-NOT-FOUND))
        )
        (map-set beneficiaries
            entity
            {
                is-eligible: (get is-eligible record),
                total-disbursed: (+ (get total-disbursed record) amount),
                last-disbursement-block: stacks-block-height,
                current-state: (get current-state record)
            }
        )
        (ok amount))
    )
)

(define-public (set-min-contribution (new-min uint))
    (begin
        (asserts! (is-admin) ERR-UNAUTHORIZED)
        (asserts! (is-valid-value new-min) ERR-INVALID-VALUE)
        (var-set treasury-min-contribution new-min)
        (ok true)
    )
)

(define-public (toggle-treasury-status)
    (begin
        (asserts! (is-admin) ERR-UNAUTHORIZED)
        (var-set treasury-operational (not (var-get treasury-operational)))
        (ok true)
    )
)

(define-public (enable-emergency-mode)
    (begin
        (asserts! (is-admin) ERR-UNAUTHORIZED)
        (var-set treasury-emergency-mode true)
        (ok true)
    )
)

(define-public (disable-emergency-mode)
    (begin
        (asserts! (is-admin) ERR-UNAUTHORIZED)
        (var-set treasury-emergency-mode false)
        (ok true)
    )
)

(define-public (update-beneficiary-state (entity principal) (state (string-ascii 20)))
    (begin
        (asserts! (is-admin) ERR-UNAUTHORIZED)
        (asserts! (is-valid-state state) ERR-INVALID-STATE)
        (asserts! (is-some (map-get? beneficiaries entity)) ERR-BENEFICIARY-NOT-FOUND)

        (let (
            (record (unwrap! (map-get? beneficiaries entity) ERR-BENEFICIARY-NOT-FOUND))
        )
        (map-set beneficiaries
            entity
            {
                is-eligible: (get is-eligible record),
                total-disbursed: (get total-disbursed record),
                last-disbursement-block: (get last-disbursement-block record),
                current-state: state
            }
        )
        (ok true))
    )
)

(define-public (transfer-admin-rights (new-admin principal))
    (begin
        (asserts! (is-admin) ERR-UNAUTHORIZED)
        (asserts! (is-valid-admin new-admin) ERR-INVALID-ADMIN)
        (var-set treasury-admin new-admin)
        (ok true)
    )
)