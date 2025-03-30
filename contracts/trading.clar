;; Trading Contract
;; Facilitates buying and selling of carbon offsets

(define-fungible-token carbon-credit)

;; Token metadata
(define-non-fungible-token carbon-credit-metadata uint)

;; Mapping of project to available credits
(define-map project-credits
  { project-id: uint }
  { available-credits: uint }
)

;; Mapping of token ID to project ID
(define-map token-projects
  { token-id: uint }
  { project-id: uint }
)

(define-data-var next-token-id uint u1)
(define-data-var admin principal tx-sender)

;; Mint new carbon credits for a verified project
(define-public (mint-credits (project-id uint) (amount uint))
  (let ((token-id (var-get next-token-id)))
    (begin
      ;; Only admin can mint
      (asserts! (is-eq tx-sender (var-get admin)) (err u403))

      ;; Mint fungible tokens
      (try! (ft-mint? carbon-credit amount tx-sender))

      ;; Create NFT metadata for this batch
      (try! (nft-mint? carbon-credit-metadata token-id tx-sender))

      ;; Update project credits
      (match (map-get? project-credits { project-id: project-id })
        existing-credits (map-set project-credits
          { project-id: project-id }
          { available-credits: (+ amount (get available-credits existing-credits)) }
        )
        (map-set project-credits
          { project-id: project-id }
          { available-credits: amount }
        )
      )

      ;; Map token to project
      (map-set token-projects
        { token-id: token-id }
        { project-id: project-id }
      )

      ;; Increment token ID
      (var-set next-token-id (+ token-id u1))

      (ok token-id)
    )
  )
)

;; List credits for sale
(define-map listings
  { seller: principal, token-id: uint }
  { amount: uint, price-per-unit: uint }
)

;; List carbon credits for sale
(define-public (list-credits (token-id uint) (amount uint) (price-per-unit uint))
  (begin
    (asserts! (is-eq (nft-get-owner? carbon-credit-metadata token-id) (some tx-sender)) (err u401))
    (asserts! (>= (ft-get-balance carbon-credit tx-sender) amount) (err u402))

    (map-set listings
      { seller: tx-sender, token-id: token-id }
      { amount: amount, price-per-unit: price-per-unit }
    )
    (ok true)
  )
)

;; Buy carbon credits
(define-public (buy-credits (seller principal) (token-id uint) (amount uint))
  (match (map-get? listings { seller: seller, token-id: token-id })
    listing (let (
      (total-price (* amount (get price-per-unit listing)))
    )
      (begin
        ;; Check if enough credits are listed
        (asserts! (<= amount (get amount listing)) (err u402))

        ;; Transfer STX from buyer to seller
        (try! (stx-transfer? total-price tx-sender seller))

        ;; Transfer carbon credits from seller to buyer
        (try! (ft-transfer? carbon-credit amount seller tx-sender))

        ;; Update or remove listing
        (if (< amount (get amount listing))
          (map-set listings
            { seller: seller, token-id: token-id }
            { amount: (- (get amount listing) amount), price-per-unit: (get price-per-unit listing) }
          )
          (map-delete listings { seller: seller, token-id: token-id })
        )

        (ok true)
      )
    )
    (err u404)
  )
)

;; Get listing details
(define-read-only (get-listing (seller principal) (token-id uint))
  (map-get? listings { seller: seller, token-id: token-id })
)

;; Get project for a token
(define-read-only (get-token-project (token-id uint))
  (map-get? token-projects { token-id: token-id })
)

;; Transfer admin rights
(define-public (transfer-admin (new-admin principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (var-set admin new-admin)
    (ok true)
  )
)

