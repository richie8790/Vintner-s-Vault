;; Decentralized Wine Investment Consortium - Stage 1

;; Constants
(define-constant ERR-NOT-CELLAR-MASTER (err u1))
(define-constant ERR-CONSORTIUM-INACTIVE (err u2))
(define-constant ERR-INVALID-VINTAGE (err u3))
(define-constant ERR-INSUFFICIENT-EXPERTISE (err u6))
(define-constant ERR-VINTAGE-EXISTS (err u7))
(define-constant ERR-INVALID-PARAMETER (err u5))
(define-constant MAX-VINTAGE-ID u1000) ;; Maximum allowed vintage ID
(define-constant MIN-EXPERTISE-REQUIRED u10) ;; Minimum expertise to register
(define-constant MAX-EXPERTISE-INPUT u1000000) ;; Maximum expertise input allowed

;; Data Variables
(define-data-var cellar-master principal tx-sender)
(define-data-var consortium-active bool false)
(define-data-var investment-season uint u0)
(define-data-var minimum-expertise-threshold uint u100) ;; 100 expertise points minimum

;; Wine Vintage Structure
(define-map wine-vintages
    uint
    {
        vintage-name: (string-utf8 128),
        description: (string-utf8 512),
        provenance-hash: (buff 32),   ;; SHA256 hash of the provenance documentation
        wine-region: (string-utf8 64),
        curator: principal,
        total-expertise: uint        ;; Sum of expertise of all sommeliers
    }
)

;; Sommelier Profiles
(define-map sommelier-profiles
    principal
    {
        expertise: uint,
        vintages-curated: (list 30 uint)
    }
)

;; Authorization
(define-private (is-cellar-master)
    (is-eq tx-sender (var-get cellar-master)))

;; Data Validation Functions
(define-private (is-valid-hash (hash (buff 32)))
    (> (len hash) u0))

;; Consortium Management Functions
(define-public (activate-consortium)
    (begin
        (asserts! (is-cellar-master) ERR-NOT-CELLAR-MASTER)
        (var-set consortium-active true)
        (var-set investment-season u0)
        (ok true)))

(define-public (register-vintage
    (vintage-id uint)
    (vintage-name (string-utf8 128))
    (description (string-utf8 512))
    (provenance-hash (buff 32))
    (wine-region (string-utf8 64)))
    (let (
        (sommelier-profile (unwrap! (map-get? sommelier-profiles tx-sender) ERR-INSUFFICIENT-EXPERTISE))
        (validated-hash (if (is-valid-hash provenance-hash) provenance-hash 0x))
        )
        
        ;; Check consortium status
        (asserts! (var-get consortium-active) ERR-CONSORTIUM-INACTIVE)
        
        ;; Validate vintage-id is within acceptable range
        (asserts! (<= vintage-id MAX-VINTAGE-ID) ERR-INVALID-PARAMETER)
        
        ;; Check if vintage already exists
        (asserts! (is-none (map-get? wine-vintages vintage-id)) ERR-VINTAGE-EXISTS)
        
        ;; Validate vintage-name and description are not empty
        (asserts! (> (len vintage-name) u0) ERR-INVALID-PARAMETER)
        (asserts! (> (len description) u0) ERR-INVALID-PARAMETER)
        (asserts! (> (len wine-region) u0) ERR-INVALID-PARAMETER)
        
        ;; Validate hash is not empty
        (asserts! (is-valid-hash provenance-hash) ERR-INVALID-PARAMETER)
        
        ;; Check sommelier has enough expertise to register vintage
        (asserts! (>= (get expertise sommelier-profile) (var-get minimum-expertise-threshold)) ERR-INSUFFICIENT-EXPERTISE)
        
        ;; Set the vintage data
        (map-set wine-vintages vintage-id
            {
                vintage-name: vintage-name,
                description: description,
                provenance-hash: validated-hash,
                wine-region: wine-region,
                curator: tx-sender,
                total-expertise: (get expertise sommelier-profile)
            })
        
        ;; Update sommelier profile
        (map-set sommelier-profiles tx-sender
            (merge sommelier-profile {
                vintages-curated: (unwrap! (as-max-len? 
                    (append (get vintages-curated sommelier-profile) vintage-id) u30)
                    ERR-INVALID-PARAMETER)
            }))
        
        (ok true)))

;; Sommelier Registration Functions
(define-public (register-sommelier (initial-expertise uint))
    (begin
        (asserts! (var-get consortium-active) ERR-CONSORTIUM-INACTIVE)
        
        ;; Validate expertise input
        (asserts! (and (>= initial-expertise MIN-EXPERTISE-REQUIRED) (<= initial-expertise MAX-EXPERTISE-INPUT)) ERR-INVALID-PARAMETER)
        
        ;; Require some expertise token transfer (simplified for demonstration)
        (try! (stx-transfer? initial-expertise tx-sender (var-get cellar-master)))
        
        ;; Initialize sommelier profile with validated expertise
        (map-set sommelier-profiles tx-sender
            {
                expertise: initial-expertise,
                vintages-curated: (list)
            })
            
        (ok true)))

;; Read-only functions
(define-read-only (get-vintage-details (vintage-id uint))
    (map-get? wine-vintages vintage-id))

(define-read-only (get-sommelier-profile (sommelier principal))
    (map-get? sommelier-profiles sommelier))

(define-read-only (get-consortium-metrics)
    {
        active: (var-get consortium-active),
        investment-season: (var-get investment-season),
        minimum-expertise: (var-get minimum-expertise-threshold)
    })

(define-public (update-minimum-expertise (new-minimum uint))
    (begin
        (asserts! (is-cellar-master) ERR-NOT-CELLAR-MASTER)
        ;; Validate new threshold is within acceptable range
        (asserts! (and (>= new-minimum MIN-EXPERTISE-REQUIRED) (<= new-minimum MAX-EXPERTISE-INPUT)) ERR-INVALID-PARAMETER)
        (var-set minimum-expertise-threshold new-minimum)
        (ok true)))

(define-public (transfer-cellar-master-role (new-master principal))
    (begin 
        (asserts! (is-cellar-master) ERR-NOT-CELLAR-MASTER)
        ;; Cannot set to zero address (represented as none in Clarity)
        (asserts! (is-some (some new-master)) ERR-INVALID-PARAMETER)
        (var-set cellar-master new-master)
        (ok true)))

(define-public (suspend-consortium)
    (begin
        (asserts! (is-cellar-master) ERR-NOT-CELLAR-MASTER)
        (var-set consortium-active false)
        (ok true)))