;; Offset Quantification Contract
;; Measures carbon impact of projects

(define-data-var admin principal tx-sender)

;; Offset data structure
(define-map offsets
  { project-id: uint }
  {
    total-tons: uint,
    verification-method: (string-utf8 100),
    verification-date: uint,
    expiration-date: uint
  }
)

;; Add or update offset data for a project (admin only)
(define-public (set-offset-data
  (project-id uint)
  (total-tons uint)
  (verification-method (string-utf8 100))
  (expiration-date uint)
)
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (map-set offsets
      { project-id: project-id }
      {
        total-tons: total-tons,
        verification-method: verification-method,
        verification-date: block-height,
        expiration-date: expiration-date
      }
    )
    (ok true)
  )
)

;; Get offset data for a project
(define-read-only (get-offset-data (project-id uint))
  (map-get? offsets { project-id: project-id })
)

;; Check if offset data is valid (not expired)
(define-read-only (is-offset-valid (project-id uint))
  (match (map-get? offsets { project-id: project-id })
    offset (< block-height (get expiration-date offset))
    false
  )
)

;; Transfer admin rights
(define-public (transfer-admin (new-admin principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (var-set admin new-admin)
    (ok true)
  )
)

