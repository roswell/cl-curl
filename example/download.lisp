(defpackage :cl-curl/example/download
  (:use :cl :cl-curl))
(in-package :cl-curl/example/download)

(cffi:defcallback write-data :size ((ptr :pointer) (size :size)
                                                   (nmemb :size) (stream :pointer))
  (let (#+nil(data-size (* size nmemb)))
    (cl-curl/functions::fwrite ptr size nmemb stream)))

(cffi:defcallback header-callback :size ((buffer :pointer) (size :size)
                                                           (nmemb :size) (stream :pointer))
  (declare (ignorable stream buffer))
  (* size nmemb))

(defun download-simple (uri path &key)
  (let ((bodyfile (fopen path "wb"))
        res)
    (unless (cffi:null-pointer-p bodyfile)
      (let ((curl (curl-easy-init)))
        (unless (cffi:null-pointer-p curl)
          (unwind-protect
               (progn
                 (curl-easy-setopt curl :url uri)
                 (curl-easy-setopt curl :followlocation 1)
                 (curl-easy-setopt curl :writefunction (cffi:callback write-data))
                 (curl-easy-setopt curl :headerfunction  (cffi:callback header-callback))
                 (curl-easy-setopt curl :writedata bodyfile)
                 (setf res (curl-easy-perform curl)))
            (curl-easy-cleanup curl)
            (cl-curl/functions::fclose bodyfile))
          (unless (zerop res)
            (return-from download-simple 2)))))))

