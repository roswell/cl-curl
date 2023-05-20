(uiop:define-package :cl-curl/main
  (:nicknames #:cl-curl)
  (:use :cl :cffi)
  (:use-reexport
   #:cl-curl/functions
   #:cl-curl/grovel
   )
  (:export :init))
(in-package :cl-curl/main)

(define-foreign-library libcurl
  (:darwin (:or "libcurl.4.dylib" "libcurl.dylib"))
  (:unix (:or "libcurl.so.4" "libcurl.so"))
  (t (:default "libcurl")))

(defun init ()
  (use-foreign-library libcurl))
