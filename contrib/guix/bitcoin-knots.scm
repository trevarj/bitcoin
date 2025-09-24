(use-modules (guix packages)
             (guix download)
             (guix build-system cmake)
             ((guix licenses) #:prefix license:)
             (gnu packages boost)
             (gnu packages dbm)
             (gnu packages libevent)
             (gnu packages upnp)
             (gnu packages qt)
             (gnu packages sqlite)
             (gnu packages pkg-config)
             (gnu packages python)
             (gnu packages linux))

(define-public bitcoin-knots
  (package
   (name "bitcoin-knots")
   (version "29.1.knots20250903")
   (source (origin
            (method url-fetch)
            (uri
             (string-append "https://github.com/bitcoinknots/bitcoin/releases/download/v"
                            version "/bitcoin-" version ".tar.gz"))
            (sha256
             (base32
              "01pm6s0db27j5gx640bw9n2rlqv7vlrgk6cbaayff23bcfa4jffq"))))
   (build-system cmake-build-system)
   (native-inputs
    (list pkg-config
          python                        ; for the tests
          util-linux                    ; provides the hexdump command for tests
          qttools-5))
   (inputs
    (list bdb-4.8                       ; 4.8 required for compatibility
          boost
          libevent
          miniupnpc
          qtbase-5
          sqlite))
   (arguments
    `(#:phases
      (modify-phases %standard-phases
                     (add-before 'configure 'make-qt-deterministic
                                 (lambda _
                                   ;; Make Qt deterministic.
                                   (setenv "QT_RCC_SOURCE_DATE_OVERRIDE" "1")
                                   #t))
                     (add-before 'build 'set-no-git-flag
                                 (lambda _
                                   ;; Make it clear we are not building from within a git repository
                                   ;; (and thus no information regarding this build is available
                                   ;; from git).
                                   (setenv "BITCOIN_GENBUILD_NO_GIT" "1")
                                   #t))
                     (add-before 'check 'set-home
                                 (lambda _
                                   (setenv "HOME" (getenv "TMPDIR")) ; tests write to $HOME
                                   #t))
                     (add-after 'check 'check-functional
                                (lambda _
                                  (invoke
                                   "python3" "./test/functional/test_runner.py"
                                   (string-append "--jobs=" (number->string (parallel-job-count))))
                                  #t)))))
   (home-page "https://bitcoinknots.org/")
   (synopsis "Enhanced fork of Bitcoin Core")
   (description
    "Bitcoin Knots connects to the Bitcoin peer-to-peer network to download and fully
validate blocks and transactions. It also includes a wallet and graphical user
interface, which can be optionally built.")
   (license license:expat)))

bitcoin-knots
