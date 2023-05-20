(defpackage :cl-curl/package
  (:use :cl))
(in-package :cl-curl/package)

(defpackage :cl-curl/grovel
  (:use :cl :cffi)
  (:export
   #:curlopt
   #:curlinfo
   ))
