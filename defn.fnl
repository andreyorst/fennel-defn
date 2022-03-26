;;; defn.fnl

(comment
 MIT License

 Copyright (c) 2022 Andrey Listopadov

 Permission is hereby granted‚ free of charge‚ to any person obtaining a copy
 of this software and associated documentation files (the "Software")‚ to deal
 in the Software without restriction‚ including without limitation the rights
 to use‚ copy‚ modify‚ merge‚ publish‚ distribute‚ sublicense‚ and/or sell
 copies of the Software‚ and to permit persons to whom the Software is
 furnished to do so‚ subject to the following conditions：

 The above copyright notice and this permission notice shall be included in all
 copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS"‚ WITHOUT WARRANTY OF ANY KIND‚ EXPRESS OR
 IMPLIED‚ INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY‚
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM‚ DAMAGES OR OTHER
 LIABILITY‚ WHETHER IN AN ACTION OF CONTRACT‚ TORT OR OTHERWISE‚ ARISING FROM‚
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 SOFTWARE.)

(local errors
  {:vararg "... is't allowed in the arglist, use & destructuring"
   :same-arity "Can't have 2 overloads with same arity"
   :arity-order "Overloads must be sorted by arities"
   :amp-arity "Variadic overload must be the last overload"
   :extra-rest-args "Only one argument allowed after &"
   :wrong-arg-amount "Wrong number of args (%s) passed to %s"
   :extra-amp "Can't have more than 1 variadic overload"})

(fn first [[x]] x)
(fn rest [[_ & xs]] xs)
(fn vfirst [x ...] x)
(fn vrest [_ ...] [...])

(fn has? [arglist sym]
  ;; searches for the given symbol in a table.
  (var has false)
  (each [_ arg (ipairs arglist) :until has]
    (set has (= sym arg)))
  has)

(fn length* [arglist]
  ;; Gets "length" of variadic arglist, stopping at first & plus 1 arg.
  ;; Additionally checks whether there are more than one arg after &.
  (var (l amp? n) (values 0 false nil))
  (each [i arg (ipairs arglist) :until amp?]
    (if (= arg '&)
        (set (amp? n) (values true i))
        (set l (+ l 1))))
  (when n
    (assert-compile (= (length arglist) (+ n 1))
                    errors.extra-rest-args
                    (. arglist (length arglist))))
  (if amp? (+ l 1) l))

(fn check-arglists [arglists]
  ;; performs a check that arglists are ordered correctly, and that
  ;; only one of multiarity arglists has the & symbol, additionally
  ;; checking for a presence of the multiple-values symbol.
  (var (size amp?) (values -1 false))
  (each [_ [arglist] (ipairs arglists)]
    (assert-compile (not (has? arglist '...)) errors.vararg arglist)
    (let [len (length* arglist)]
      (assert-compile (not= size len) errors.same-arity arglist)
      (assert-compile (< size len) errors.arity-order arglist)
      (assert-compile (not amp?) (if (has? arglist '&)
                                     errors.extra-amp
                                     errors.amp-arity) arglist)
      (set size len)
      (set amp? (has? arglist '&)))))

(fn gen-match-fn [name doc arglists]
  ;; automated multi-arity dispatch generator
  (check-arglists arglists)
  (let [match-body `(match (select :# ...))]
    (var variadic? false)
    (each [_ [arglist & body] (ipairs arglists)]
      (table.insert match-body (if (has? arglist '&) (do (set variadic? true) (sym :_)) (length arglist)))
      (table.insert match-body `(let [,arglist [...]] ,(unpack body))))
    (when (not variadic?)
      (table.insert match-body (sym :_))
      (table.insert match-body `(error (: ,errors.wrong-arg-amount :format ,(sym :_) ,(tostring name)))))
    `(fn ,name [...]
       {:fnl/docstring ,doc
        :fnl/arglist ,(icollect [_ [arglist] (ipairs arglists)]
                        (list arglist))}
       ,match-body)))

(fn gen-fn [name doc arglist body]
  (check-arglists [[arglist]])
  (if (has? arglist '&)
      `(fn ,name [...]
         {:fnl/docstring ,doc
          :fnl/arglist ,arglist}
         (let [,arglist [...]]
           ,body))
      `(fn ,name ,arglist
         {:fnl/docstring ,doc
          :fnl/arglist ,arglist}
         ,body)))

(fn defn [name ...]
  (let [doc? (if (= :string (type (vfirst ...))) (vfirst ...))
        args (if doc? (vrest ...) [...])]
    (if (list? (first args))
        (gen-match-fn name doc? args)
        (let [[arglist & body] args]
          (gen-fn name doc? arglist `(do ,(unpack body)))))))

{: defn}
