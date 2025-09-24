;; Example usage:
;; guix shell -f ../bitcoin-core.scm --with-source=capnproto=./depends/sources/capnproto-cxx-1.2.0.tar.gz --without-tests=capnproto

(use-modules (guix packages)
             (guix download)
             (guix build-system cmake)
             (guix gexp)
             ((guix licenses) #:prefix license:)
             (gnu packages boost)
             (gnu packages dbm)
             (gnu packages libevent)
             (gnu packages upnp)
             (gnu packages qt)
             (gnu packages serialization)
             (gnu packages sqlite)
             (gnu packages pkg-config)
             (gnu packages python)
             (gnu packages linux))

(define-public bitcoin-core
  ;; The support lifetimes for bitcoin-core versions can be found in
  ;; <https://bitcoincore.org/en/lifecycle/#schedule>.
  (package
    (name "bitcoin-core")
    (version "30-dirty")
    (source (local-file "./core" #:recursive? #t))
    (build-system cmake-build-system)
    (native-inputs
     (list pkg-config
           python ; for the tests
           util-linux ; provides the hexdump command for tests
           qttools-5))
    (inputs
     (list bdb-4.8 ; 4.8 required for compatibility
           boost
           capnproto
           libevent
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
    (home-page "https://bitcoincore.org/")
    (synopsis "Bitcoin peer-to-peer client")
    (description
     "Bitcoin is a digital currency that enables instant payments to anyone
anywhere in the world.  It uses peer-to-peer technology to operate without
central authority: managing transactions and issuing money are carried out
collectively by the network.  Bitcoin Core is the reference implementation
of the bitcoin protocol.  This package provides the Bitcoin Core command
line client and a client based on Qt.")
    (license license:expat)))

bitcoin-core
