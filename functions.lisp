(defpackage :cl-curl/functions
  (:use :cl :cffi)
  (:export #:curl-easy-init
           #:curl-easy-cleanup
           #:curl-easy-setopt
           #:curl-easy-perform
           #:curl-easy-getinfo
           #:curl-version
           #:fopen
           #:fclos
           ))
(in-package :cl-curl/functions)
(eval-when (:compile-toplevel :load-toplevel :execute)
  (defctype easy-handle :pointer)
  (defctype curl-code :int))

;;CURL *curl_easy_init();
(defcfun "curl_easy_init" easy-handle)
;;void curl_easy_cleanup(CURL *handle);
(defcfun "curl_easy_cleanup" :void
  (handle easy-handle))
;;CURLcode curl_easy_setopt(CURL *handle, CURLoption option, parameter);
(defcfun (curl-easy-setopt% "curl_easy_setopt") curl-code 
  (handle easy-handle)
  (option :int)
  &rest)
;;CURLcode curl_easy_perform(CURL *easy_handle);
(defcfun "curl_easy_perform" curl-code
  (handle easy-handle))
;;CURLcode curl_easy_getinfo(CURL *curl, CURLINFO info, ... );
(defcfun "curl_easy_getinfo" curl-code
  (handle easy-handle)
  (info :int)
  &rest)

(defun curl-easy-setopt (handle option val &optional type)
  (unless type
    (setf type (cond ((stringp val) :string)
                     ((integerp val) :long)
                     (t :pointer))))
  (setf option (cffi:foreign-enum-value 'cl-curl/grovel:curlopt option))
  (cond ((eql type :string)
         (curl-easy-setopt% handle option :string val))
        ((eql type :long)
         (curl-easy-setopt% handle option :long val))
        ((eql type :pointer)
         (curl-easy-setopt% handle option :pointer val))))
         
  
;;; https://curl.se/libcurl/c/
;;

;;char *curl_version();
(defcfun "curl_version" :string)
;;
(defcfun "fopen" :pointer
  (path :string)
  (mode :string))
(defcfun "fclose" :int
  (file :pointer))
;; size_t    fwrite(const void *restrict ptr, size_t size, size_t nitems, FILE *restrict stream);
(defcfun "fwrite" :size
  (ptr :pointer)
  (size :size)
  (nitems :size)
  (stream :pointer))
