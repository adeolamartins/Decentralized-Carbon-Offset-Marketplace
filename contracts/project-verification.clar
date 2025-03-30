;; Project Verification Contract
;; Validates carbon reduction initiatives

(define-data-var admin principal tx-sender)

;; Project status: 0 = pending, 1 = verified, 2 = rejected
(define-map projects
  { project-id: uint }
  {
    owner: principal,
    name: (string-utf8 100),
    description: (string-utf8 500),
    location: (string-utf8 100),
    status: uint,
    verification-date: uint
  }
)

(define-data-var next-project-id uint u1)

;; Register a new carbon reduction project
(define-public (register-project (name (string-utf8 100)) (description (string-utf8 500)) (location (string-utf8 100)))
  (let ((project-id (var-get next-project-id)))
    (begin
      (map-set projects
        { project-id: project-id }
        {
          owner: tx-sender,
          name: name,
          description: description,
          location: location,
          status: u0,
          verification-date: u0
        }
      )
      (var-set next-project-id (+ project-id u1))
      (ok project-id)
    )
  )
)

;; Verify a project (admin only)
(define-public (verify-project (project-id uint))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (match (map-get? projects { project-id: project-id })
      project (begin
        (map-set projects
          { project-id: project-id }
          (merge project {
            status: u1,
            verification-date: block-height
          })
        )
        (ok true)
      )
      (err u404)
    )
  )
)

;; Reject a project (admin only)
(define-public (reject-project (project-id uint))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (match (map-get? projects { project-id: project-id })
      project (begin
        (map-set projects
          { project-id: project-id }
          (merge project {
            status: u2,
            verification-date: block-height
          })
        )
        (ok true)
      )
      (err u404)
    )
  )
)

;; Get project details
(define-read-only (get-project (project-id uint))
  (map-get? projects { project-id: project-id })
)

;; Transfer admin rights
(define-public (transfer-admin (new-admin principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (var-set admin new-admin)
    (ok true)
  )
)

