;;don't edit
(defsystem "cl-curl"
  :defsystem-depends-on ("cffi-grovel")
  :class :package-inferred-system
  :license "mit"
  :author "SANO Masatoshi"
  :mailto "snmsts@gmail.com"
  :build-operation monolithic-concatenate-source-op
  :build-pathname "curl"
  :serial t
  :components
  ((:file "package")
   (:cffi-grovel-file "grovel")
   (:file "functions")
   (:file "main")))
