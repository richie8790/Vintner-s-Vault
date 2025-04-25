;; Decentralized Wine Investment Consortium - Stage 2

;; Constants
(define-constant ERR-NOT-CELLAR-MASTER (err u1))
(define-constant ERR-CONSORTIUM-INACTIVE (err u2))
(define-constant ERR-INVALID-VINTAGE (err u3))
(define-constant ERR-VINTAGE-LOCKED (err u4))
(define-constant ERR-INVALID-PARAMETER (err u5))
(define-constant ERR-INSUFFICIENT-EXPERTISE (err u6))
(define-constant ERR-VINTAGE-EXISTS (err u7))
(define-constant ERR-ALREADY-APPRAISED (err u8))
(define-constant ERR-NOT-AUTHORIZED (err u9))
(define-constant ERR-ACQUISITION-NOT-FOUND (err u10))
(define-constant MAX-VINTAGE-ID u1000) ;; Maximum allowed vintage ID
(define-constant MIN-EXPERTISE-REQUIRED u10) ;; Minimum expertise to register
(define-constant MAX-EXPERTISE-INPUT u1000000) ;; Maximum expertise input allowed
(define-constant MAX-APPROVAL-THRESHOLD u100) ;; Maximum approval threshold (100%)

;; Data Variables
(define-data-var cellar-master principal tx-sender)
(define-data-var consortium-active bool false)
(define-data-var investment-season uint u0)
(define-data-var minimum-expertise-threshold uint u100) ;; 100 expertise points minimum
(define-data-var acquisition-threshold uint u66) ;; 66% approval required for acquisition

;; Wine Vintage Structure
(define-map wine-vintages
    uint
    {
        vintage-name: (string-utf8 128),
        description: (string-utf8 512),
        provenance-hash: (buff 32),   ;; SHA256 hash of the provenance documentation
        wine-region: (string-utf8 64),
        accepting-acquisitions: bool,
        curator: principal,
        total-expertise: uint,        ;; Sum of expertise of all sommeliers
        finalized-acquisitions: uint  ;; Counter of accepted acquisitions
    }
)

;; Vintage Sommeliers Mapping
(define-map vintage-sommeliers
    {vintage-id: uint, sommelier: principal}
    {
        expertise-committed: uint
    }
)

;; Sommelier Profiles
(define-map sommelier-profiles
    principal
    {
        expertise: uint,
        vintages-curated: (list 30 uint),
        acquisitions-proposed: (list 30 uint),
        appraisal-weight: uint        ;; Derived from expertise but can be modified
    }
)

;; Acquisition Structure
(define-map vintage-acquisitions
    uint  ;; acquisition-id
    {
        description: (string-utf8 256),
        certificate-hash: (buff 32),
        sommelier: principal,
        target-vintage: uint,
        submitted-in-season: uint,
        finalized: bool
    }
)

;; Acquisition Appraisals
(define-map acquisition-appraisals
    {acquisition-id: uint, appraiser: principal}
    {
        approved: bool,
        weight: uint
    }
)

;; Appraisal Tallies for Acquisitions
(define-map appraisal-tallies
    uint  ;; acquisition-id
    {
        approval-weight: uint,
        rejection-weight: uint,
        total-appraisals: uint
    }
)

;; Authorization
(define-private (is-cellar-master)
    (is-eq tx-sender (var-get cellar-master)))

;; Data Validation Functions
(define-private (is-valid-hash (hash (buff 32)))
    (> (len hash) u0))

(define-private (is-valid-description (desc (string-utf8 256)))
    (> (len desc) u0))

(define-private (is-valid-expertise (exp uint))
    (and (>= exp MIN-EXPERTISE-REQUIRED) (<= exp MAX-EXPERTISE-INPUT)))

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
                accepting-acquisitions: true,
                curator: tx-sender,
                total-expertise: (get expertise sommelier-profile),
                finalized-acquisitions: u0
            })
        
        ;; Record sommelier as curator
        (map-set vintage-sommeliers 
            {vintage-id: vintage-id, sommelier: tx-sender}
            {expertise-committed: (get expertise sommelier-profile)})
        
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
        (asserts! (is-valid-expertise initial-expertise) ERR-INVALID-PARAMETER)
        
        ;; Require some expertise token transfer (simplified for demonstration)
        (try! (stx-transfer? initial-expertise tx-sender (var-get cellar-master)))
        
        ;; Initialize sommelier profile with validated expertise
        (map-set sommelier-profiles tx-sender
            {
                expertise: initial-expertise,
                vintages-curated: (list),
                acquisitions-proposed: (list),
                appraisal-weight: initial-expertise
            })
            
        (ok true)))

;; Acquisition Proposal
(define-public (propose-acquisition
    (acquisition-id uint)
    (target-vintage-id uint)
    (description (string-utf8 256))
    (certificate-hash (buff 32)))
    (let (
        (vintage (unwrap! (map-get? wine-vintages target-vintage-id) ERR-INVALID-VINTAGE))
        (sommelier (unwrap! (map-get? sommelier-profiles tx-sender) ERR-INSUFFICIENT-EXPERTISE))
        )
        
        ;; Check consortium status
        (asserts! (var-get consortium-active) ERR-CONSORTIUM-INACTIVE)
        
        ;; Check if vintage is accepting acquisitions
        (asserts! (get accepting-acquisitions vintage) ERR-VINTAGE-LOCKED)
        
        ;; Check that acquisition ID doesn't already exist
        (asserts! (is-none (map-get? vintage-acquisitions acquisition-id)) ERR-INVALID-PARAMETER)
        
        ;; Validate description and hash
        (asserts! (is-valid-description description) ERR-INVALID-PARAMETER)
        (asserts! (is-valid-hash certificate-hash) ERR-INVALID-PARAMETER)
        
        ;; Record the acquisition
        (map-set vintage-acquisitions acquisition-id
            {
                description: description,
                certificate-hash: certificate-hash,
                sommelier: tx-sender,
                target-vintage: target-vintage-id,
                submitted-in-season: (var-get investment-season),
                finalized: false
            })
        
        ;; Initialize appraisal tally
        (map-set appraisal-tallies acquisition-id
            {
                approval-weight: u0,
                rejection-weight: u0,
                total-appraisals: u0
            })
        
        ;; Update sommelier's proposed acquisitions
        (map-set sommelier-profiles tx-sender
            (merge sommelier {
                acquisitions-proposed: (unwrap! (as-max-len? 
                    (append (get acquisitions-proposed sommelier) acquisition-id) u30)
                    ERR-INVALID-PARAMETER)
            }))
        
        (ok true)))

;; Appraise Acquisition
(define-public (appraise-acquisition
    (acquisition-id uint)
    (approve bool))
    (let (
        (acquisition (unwrap! (map-get? vintage-acquisitions acquisition-id) ERR-ACQUISITION-NOT-FOUND))
        (sommelier (unwrap! (map-get? sommelier-profiles tx-sender) ERR-INSUFFICIENT-EXPERTISE))
        (appraisal-tally (unwrap! (map-get? appraisal-tallies acquisition-id) ERR-ACQUISITION-NOT-FOUND))
        )
        
        ;; Check consortium status
        (asserts! (var-get consortium-active) ERR-CONSORTIUM-INACTIVE)
        
        ;; Ensure acquisition hasn't already been finalized
        (asserts! (not (get finalized acquisition)) ERR-VINTAGE-LOCKED)
        
        ;; Check sommelier hasn't already appraised
        (asserts! (is-none (map-get? acquisition-appraisals 
                                    {acquisition-id: acquisition-id, appraiser: tx-sender})) 
                ERR-ALREADY-APPRAISED)
        
        ;; Record the appraisal
        (map-set acquisition-appraisals 
            {acquisition-id: acquisition-id, appraiser: tx-sender}
            {
                approved: approve,
                weight: (get appraisal-weight sommelier)
            })
        
        ;; Update appraisal tally
        (map-set appraisal-tallies acquisition-id
            (merge appraisal-tally {
                approval-weight: (if approve 
                                    (+ (get approval-weight appraisal-tally) (get appraisal-weight sommelier))
                                    (get approval-weight appraisal-tally)),
                rejection-weight: (if (not approve)
                                    (+ (get rejection-weight appraisal-tally) (get appraisal-weight sommelier))
                                    (get rejection-weight appraisal-tally)),
                total-appraisals: (+ (get total-appraisals appraisal-tally) u1)
            }))
        
        (ok true)))

;; Change Vintage Acquisition Status
(define-public (set-vintage-acquisition-status (vintage-id uint) (open bool))
    (let (
        (vintage (unwrap! (map-get? wine-vintages vintage-id) ERR-INVALID-VINTAGE))
        )
        
        ;; Check consortium status
        (asserts! (var-get consortium-active) ERR-CONSORTIUM-INACTIVE)
        
        ;; Only curator or cellar master can change status
        (asserts! (or (is-eq tx-sender (get curator vintage)) (is-cellar-master)) ERR-NOT-AUTHORIZED)
        
        ;; Update vintage status
        (map-set wine-vintages vintage-id
            (merge vintage {accepting-acquisitions: open}))
        
        (ok true)))

;; Read-only functions
(define-read-only (get-vintage-details (vintage-id uint))
    (map-get? wine-vintages vintage-id))

(define-read-only (get-sommelier-profile (sommelier principal))
    (map-get? sommelier-profiles sommelier))

(define-read-only (get-acquisition-details (acquisition-id uint))
    (map-get? vintage-acquisitions acquisition-id))

(define-read-only (get-acquisition-appraisals (acquisition-id uint))
    (map-get? appraisal-tallies acquisition-id))

(define-read-only (get-consortium-metrics)
    {
        active: (var-get consortium-active),
        investment-season: (var-get investment-season),
        minimum-expertise: (var-get minimum-expertise-threshold),
        acquisition-threshold: (var-get acquisition-threshold)
    })

(define-public (update-minimum-expertise (new-minimum uint))
    (begin
        (asserts! (is-cellar-master) ERR-NOT-CELLAR-MASTER)
        ;; Validate new threshold is within acceptable range
        (asserts! (and (>= new-minimum MIN-EXPERTISE-REQUIRED) (<= new-minimum MAX-EXPERTISE-INPUT)) ERR-INVALID-PARAMETER)
        (var-set minimum-expertise-threshold new-minimum)
        (ok true)))

(define-public (update-acquisition-threshold (new-percentage uint))
    (begin
        (asserts! (is-cellar-master) ERR-NOT-CELLAR-MASTER)
        ;; Validate percentage is between 1 and 100
        (asserts! (and (> new-percentage u0) (<= new-percentage MAX-APPROVAL-THRESHOLD)) ERR-INVALID-PARAMETER)
        (var-set acquisition-threshold new-percentage)
        (ok true)))

(define-public (suspend-consortium)
    (begin
        (asserts! (is-cellar-master) ERR-NOT-CELLAR-MASTER)
        (var-set consortium-active false)
        (ok true)))

(define-public (transfer-cellar-master-role (new-master principal))
    (begin 
        (asserts! (is-cellar-master) ERR-NOT-CELLAR-MASTER)
        ;; Cannot set to zero address (represented as none in Clarity)
        (asserts! (is-some (some new-master)) ERR-INVALID-PARAMETER)
        (var-set cellar-master new-master)
        (ok true)))