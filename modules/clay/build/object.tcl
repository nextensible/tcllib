oo::define oo::object {

  ###
  # description:
  # The [method clay] method allows an object access
  # to a combination of its own clay data as
  # well as to that of its class
  # ensemble:
  # ancestors {
  #   arglist {}
  #   description {Return the class this object belongs to, all classes mixed into this object, and all ancestors of those classes in search order.}
  # }
  # cget {
  #   arglist {field {mandatory 1 positional 1}}
  #   description {
  # Pull a value from either the object's clay structure or one of its constituent classes that matches the field name.
  # The order of search us:
  # [para] 1. The as a value in local dict variable config
  # [para] 2. The as a value in local dict variable clay
  # [para] 3. As a leaf in any ancestor as a root of the clay tree
  # [para] 4. As a leaf in any ancestor as [const const] [emph field]
  # [para] 5. As a leaf in any ancestor as [const option] [emph field] [const default]
  #   }
  # }
  # delegate {
  #   arglist {stub {mandatory 0 positional 1} object {mandatory 0 positional 1}}
  #   description {
  # Introspect or control method delegation. With no arguments, the method will return a
  # key/value list of stubs and objects. With just the [arg stub] argument, the method will
  # return the object (if any) attached to the stub. With a [arg stub] and an [arg object]
  # this command will forward all calls to the method [arg stub] to the [arg object].
  # }
  # }
  # dump { arglist {} description {Return a complete dump of this object's clay data, as well as the data from all constituent classes recursively blended in.}}
  # ensemble_map {arglist {} description {Return a dictionary describing the method ensembles to be assembled for this object}}
  # eval {arglist {script {mandatory 1 positional 1}} description {Evaluated a script in the namespace of this object}}
  # evolve {arglist {} description {Trigger the [method InitializePublic] private method}}
  # exists {arglist {path {mandatory 1 positional 1 repeating 1}} description {Returns 1 if [emph path] exists in either the object's clay data. Values greater than one indicate the element exists in one of the object's constituent classes. A value of zero indicates the path could not be found.}}
  # flush {arglist {} description {Wipe any caches built by the clay implementation}}
  # forward {arglist {method {positional 1 mandatory 1} object {positional 1 mandatory 1}} description {A convenience wrapper for
  # [example {oo::objdefine [self] forward {*}$args}]
  # }
  # }
  # get {arglist {path {mandatory 1 positional 1 repeating 1}}
  #   description {Pull a chunk of data from the clay system. If the last element of [emph path] is a branch (ends in a slash /),
  #   returns a recursive merge of all data from this object and it's constituent classes of the data in that branch.
  #   If the last element is a leaf, search this object for a matching leaf, or search all  constituent classes for a matching
  #   leaf and return the first value found.
  #   If no value is found, returns an empty string.
  # }
  # }
  # leaf {arglist {path {mandatory 1 positional 1 repeating 1}} description {A modified get which is tailored to pull only leaf elements}}
  # merge {arglist {dict {mandatory 1 positional 1 repeating 1}} description {Recursively merge the dictionaries given into the object's local clay storage.}}
  # mixin {arglist {class {mandatory 1 positional 1 repeating 1}} description {
  # Perform [lb]oo::objdefine [lb]self[rb] mixin[rb] on this object, with a few additional rules:
  #   Prior to the call, for any class was previously mixed in, but not in the new result, execute the script registered to mixin/ unmap-script (if given.)
  #   For all new classes, that were not present prior to this call, after the native TclOO mixin is invoked, execute the script registered to mixin/ map-script (if given.)
  #   Fall all classes that are now present and “mixed in”, execute the script registered to mixin/ react-script (if given.)
  # }}
  # mixinmap {
  #   arglist {stub {mandatory 0 positional 1} classes {mandatory 0 positional 1}}
  #   description {With no arguments returns the map of stubs and classes mixed into the current object. When only stub is given,
  #  returns the classes mixed in on that stub. When stub and classlist given, replace the classes currently on that stub with the given
  #  classes and invoke clay mixin on the new matrix of mixed in classes.
  # }
  # }
  # provenance {arglist {path {mandatory 1 positional 1 repeating 1}} description {Return either [const self] if that path exists in the current object, or return the first class (if any) along the clay search path which contains that element.}}
  # replace {arglist {dictionary {mandatory 1 positional 1}} description {Replace the contents of the internal clay storage with the dictionary given.}}
  # source {arglist {filename {mandatory 1 positional 1}} description {Source the given filename within the object's namespace}}
  # set {arglist {path {mandatory 1 positional 1 repeating 1} value {mandatory 1 postional 1}} description {Merge the conents of [const value] with the object's clay storage at [const path].}}
  ###
  method clay {submethod args} {
    my variable clay claycache clayorder config option_canonical
    if {![info exists clay]} {set clay {}}
    if {![info exists claycache]} {set claycache {}}
    if {![info exists config]} {set config {}}
    if {![info exists clayorder] || [llength $clayorder]==0} {
      set clayorder [::clay::ancestors [info object class [self]] {*}[info object mixins [self]]]
    }
    switch $submethod {
      ancestors {
        return $clayorder
      }
      cget {
        # Leaf searches return one data field at a time
        # Search in our local dict
        if {[llength $args]==1} {
          set field [string trim [lindex $args 0] -:/]
          if {[info exists option_canonical($field)]} {
            set field $option_canonical($field)
          }
          if {[dict exists $config $field]} {
            return [dict get $config $field]
          }
        }
        set path [::dicttool::storage $args]
        if {[dict exists $clay {*}$path]} {
          return [dict get $clay {*}$path]
        }
        # Search in our local cache
        if {[dict exists $claycache {*}$path]} {
          if {[dict exists $claycache {*}$path .]} {
            return [dict remove [dict get $claycache {*}$path] .]
          } else {
            return [dict get $claycache {*}$path]
          }
        }
        # Search in the in our list of classes for an answer
        foreach class $clayorder {
          if {[$class clay exists {*}$path]} {
            set value [$class clay get {*}$path]
            dict set claycache {*}$path $value
            return $value
          }
          if {[$class clay exists const {*}$path]} {
            set value [$class clay get const {*}$path]
            dict set claycache {*}$path $value
            return $value
          }
          if {[$class clay exists option {*}$path default]} {
            set value [$class clay get option {*}$path default]
            dict set claycache {*}$path $value
            return $value
          }
        }
        return {}
      }
      delegate {
        if {![dict exists $clay .delegate <class>]} {
          dict set clay .delegate <class> [info object class [self]]
        }
        if {[llength $args]==0} {
          return [dict get $clay .delegate]
        }
        if {[llength $args]==1} {
          set stub <[string trim [lindex $args 0] <>]>
          if {![dict exists $clay .delegate $stub]} {
            return {}
          }
          return [dict get $clay .delegate $stub]
        }
        if {([llength $args] % 2)} {
          error "Usage: delegate
    OR
    delegate stub
    OR
    delegate stub OBJECT ?stub OBJECT? ..."
        }
        foreach {stub object} $args {
          set stub <[string trim $stub <>]>
          dict set clay .delegate $stub $object
          oo::objdefine [self] forward ${stub} $object
          oo::objdefine [self] export ${stub}
        }
      }
      dump {
        # Do a full dump of clay data
        set result {}
        # Search in the in our list of classes for an answer
        foreach class $clayorder {
          ::dicttool::dictmerge result [$class clay dump]
        }
        ::dicttool::dictmerge result $clay
        return $result
      }
      ensemble_map {
        set ensemble [lindex $args 0]
        my variable claycache
        set mensemble [string trim $ensemble :/]
        if {[dict exists $claycache method_ensemble $mensemble]} {
          return [dicttool::sanitize [dict get $claycache method_ensemble $mensemble]]
        }
        set emap [my clay dget method_ensemble $mensemble]
        dict set claycache method_ensemble $mensemble $emap
        return [dicttool::sanitize $emap]
      }
      eval {
        set script [lindex $args 0]
        set buffer {}
        set thisline {}
        foreach line [split $script \n] {
          append thisline $line
          if {![info complete $thisline]} {
            append thisline \n
            continue
          }
          set thisline [string trim $thisline]
          if {[string index $thisline 0] eq "#"} continue
          if {[string length $thisline]==0} continue
          if {[lindex $thisline 0] eq "my"} {
            # Line already calls out "my", accept verbatim
            append buffer $thisline \n
          } elseif {[string range $thisline 0 2] eq "::"} {
            # Fully qualified commands accepted verbatim
            append buffer $thisline \n
          } elseif {
            append buffer "my $thisline" \n
          }
          set thisline {}
        }
        eval $buffer
      }
      evolve -
      initialize {
        my InitializePublic
      }
      exists {
        # Leaf searches return one data field at a time
        # Search in our local dict
        set path [::dicttool::storage $args]
        if {[dict exists $clay {*}$path]} {
          return 1
        }
        # Search in our local cache
        if {[dict exists $claycache {*}$path]} {
          return 2
        }
        set count 2
        # Search in the in our list of classes for an answer
        foreach class $clayorder {
          incr count
          if {[$class clay exists {*}$path]} {
            return $count
          }
        }
        return 0
      }
      flush {
        set claycache {}
        set clayorder [::clay::ancestors [info object class [self]] {*}[info object mixins [self]]]
      }
      forward {
        oo::objdefine [self] forward {*}$args
      }
      dget {
        # Search in our local cache
        set path [::dicttool::storage $args]
        #if {[dict exists $claycache {*}$path]} {
        #  return [dict get $claycache {*}$path]
        #}
        if {[dict exists $clay {*}$path .]} {
          # Path is a branch
          set result {}
          foreach class [lreverse $clayorder] {
            if {[$class clay exists {*}$path .]} {
              set value [$class clay dget {*}$path]
              ::dicttool::dictmerge result $value
            }
          }
          ::dicttool::dictmerge result [dict get $clay {*}$path]
          dict set claycache {*}$path $result
          return $result
        } elseif {[dict exists $clay {*}$path]} {
          # Path is a leaf
          return [dict get $clay {*}$path]
        }
        # Search in the in our list of classes for an answer
        set found 0
        foreach class $clayorder {
          if {[$class clay exists {*}$path .]} {
            set found 1
            break
          }
          if {[$class clay exists {*}$path]} {
            # Found a leaf.
            set result [$class clay get {*}$path]
            dict set claycache {*}$path $result
            return $result
          }
        }
        set result {}
        if {$found} {
          # One of our ancestors has this as a branch
          # Do a recursive merge across all classes
          foreach class [lreverse $clayorder] {
            if {[$class clay exists {*}$path .]} {
              set value [$class clay dget {*}$path]
              ::dicttool::dictmerge result $value
            }
          }
        }
        dict set claycache {*}$path $result
        return $result
      }
      getnull -
      get {
        set path [::dicttool::storage $args]
        if {[dict exists $claycache {*}$path .]} {
          return [::dicttool::sanitize [dict get $claycache {*}$path]]
        }
        if {[dict exists $claycache {*}$path]} {
          return [dict get $claycache {*}$path]
        }
        if {[dict exists $clay {*}$path] && ![dict exists $clay {*}$path .]} {
          # Path is a leaf
          return [dict get $clay {*}$path]
        }
        set found 0
        set branch [dict exists $clay {*}$path .]
        foreach class $clayorder {
          if {[$class clay exists {*}$path .]} {
            set found 1
            break
          }
          if {!$branch && [$class clay exists {*}$path]} {
            set result [$class clay dget {*}$path]
            dict set claycache {*}$path $result
            return $result
          }
        }
        # Path is a branch
        set result {}
        foreach class [lreverse $clayorder] {
          if {[$class clay exists {*}$path .]} {
            set value [$class clay dget {*}$path]
            ::dicttool::dictmerge result $value
          }
        }
        if {[dict exists $clay {*}$path .]} {
          ::dicttool::dictmerge result [dict get $clay {*}$path]
        }
        dict set claycache {*}$path $result
        return [dicttool::sanitize $result]
      }
      leaf {
        # Leaf searches return one data field at a time
        # Search in our local dict
        set path [::dicttool::storage $args]
        if {[dict exists $clay {*}$path .]} {
          return [dicttool::sanitize [dict get $clay {*}$path]]
        }
        if {[dict exists $clay {*}$path]} {
          return [dict get $clay {*}$path]
        }
        # Search in our local cache
        if {[dict exists $claycache {*}$path .]} {
          return [dicttool::sanitize [dict get $claycache {*}$path]]
        }
        if {[dict exists $claycache {*}$path]} {
          return [dict get $claycache {*}$path]
        }
        # Search in the in our list of classes for an answer
        foreach class $clayorder {
          if {[$class clay exists {*}$path]} {
            set value [$class clay get {*}$path]
            dict set claycache {*}$path $value
            return $value
          }
        }
      }
      merge {
        foreach arg $args {
          ::dicttool::dictmerge clay {*}$arg
        }
      }
      mixin {
        ###
        # Mix in the class
        ###
        set prior  [info object mixins [self]]
        set newmixin {}
        foreach item $args {
          lappend newmixin ::[string trimleft $item :]
        }
        set newmap $args
        foreach class $prior {
          if {$class ni $newmixin} {
            set script [$class clay search mixin/ unmap-script]
            if {[string length $script]} {
              if {[catch $script err errdat]} {
                puts stderr "[self] MIXIN ERROR POPPING $class:\n[dict get $errdat -errorinfo]"
              }
            }
          }
        }
        ::oo::objdefine [self] mixin {*}$args
        ###
        # Build a compsite map of all ensembles defined by the object's current
        # class as well as all of the classes being mixed in
        ###
        my InitializePublic
        foreach class $newmixin {
          if {$class ni $prior} {
            set script [$class clay search mixin/ map-script]
            if {[string length $script]} {
              if {[catch $script err errdat]} {
                puts stderr "[self] MIXIN ERROR PUSHING $class:\n[dict get $errdat -errorinfo]"
              }
            }
          }
        }
        foreach class $newmixin {
          set script [$class clay search mixin/ react-script]
          if {[string length $script]} {
            if {[catch $script err errdat]} {
              puts stderr "[self] MIXIN ERROR PEEKING $class:\n[dict get $errdat -errorinfo]"
            }
            break
          }
        }
      }
      mixinmap {
        my variable clay
        if {![dict exists $clay .mixin]} {
          dict set clay .mixin {}
        }
        if {[llength $args]==0} {
          return [dict get $clay .mixin]
        } elseif {[llength $args]==1} {
          return [dict getnull $clay .mixin [lindex $args 0]]
        } else {
          foreach {slot classes} $args {
            dict set clay .mixin $slot $classes
          }
          set claycache {}
          set classlist {}
          foreach {item class} [dict get $clay .mixin] {
            if {$class ne {}} {
              lappend classlist $class
            }
          }
          my clay mixin {*}$classlist
        }
      }
      provenance {
        if {[dict exists $clay {*}$args]} {
          return self
        }
        foreach class $clayorder {
          if {[$class clay exists {*}$args]} {
            return $class
          }
        }
        return {}
      }
      replace {
        set clay [lindex $args 0]
      }
      source {
        source [lindex $args 0]
      }
      set {
        #puts [list [self] clay SET {*}$args]
        set claycache {}
        ::dicttool::dictset clay {*}$args
      }
      default {
        dict $submethod clay {*}$args
      }
    }
  }

  ###
  # Instantiate variables. Called on object creation and during clay mixin.
  ###
  method InitializePublic {} {
    my variable clayorder clay claycache config option_canonical
    set claycache {}
    set clayorder [::clay::ancestors [info object class [self]] {*}[info object mixins [self]]]
    if {![info exists clay]} {
      set clay {}
    }
    if {![info exists config]} {
      set config {}
    }
    dict for {var value} [my clay get variable] {
      if { $var in {. clay} } continue
      set var [string trim $var :/]
      my variable $var
      if {![info exists $var]} {
        if {$::clay::trace>2} {puts [list initialize variable $var $value]}
        set $var $value
      }
    }
    dict for {var value} [my clay get dict/] {
      if { $var in {. clay} } continue
      set var [string trim $var :/]
      my variable $var
      if {![info exists $var]} {
        set $var {}
      }
      foreach {f v} $value {
        if {![dict exists ${var} $f]} {
          if {$::clay::trace>2} {puts [list initialize dict $var $f $v]}
          dict set ${var} $f $v
        }
      }
    }
    foreach {var value} [my clay get dict/] {
      if { $var in {. clay} } continue
      set var [string trim $var :/]
      foreach {f v} [my clay get $var/] {
        if {![dict exists ${var} $f]} {
          if {$::clay::trace>2} {puts [list initialize dict (from const) $var $f $v]}
          dict set ${var} $f $v
        }
      }
    }
    foreach {var value} [my clay get array/] {
      if { $var in {. clay} } continue
      set var [string trim $var :/]
      if { $var eq {clay} } continue
      my variable $var
      if {![info exists $var]} { array set $var {} }
      foreach {f v} $value {
        if {![array exists ${var}($f)]} {
          if {$::clay::trace>2} {puts [list initialize array $var\($f\) $v]}
          set ${var}($f) $v
        }
      }
    }
    foreach {var value} [my clay get array/] {
      if { $var in {. clay} } continue
      set var [string trim $var :/]
      foreach {f v} [my clay get $var/] {
        if {![array exists ${var}($f)]} {
          if {$::clay::trace>2} {puts [list initialize array (from const) $var\($f\) $v]}
          set ${var}($f) $v
        }
      }
    }
    foreach {field info} [my clay get option/] {
      if { $field in {. clay} } continue
      set field [string trim $field -/:]
      foreach alias [dict getnull $info aliases] {
        set option_canonical($alias) $field
      }
      if {[dict exists $config $field]} continue
      set getcmd [dict getnull $info default-command]
      if {$getcmd ne {}} {
        set value [{*}[string map [list %field% $field %self% [namespace which my]] $getcmd]]
      } else {
        set value [dict getnull $info default]
      }
      dict set config $field $value
      set setcmd [dict getnull $info set-command]
      if {$setcmd ne {}} {
        {*}[string map [list %field% [list $field] %value% [list $value] %self% [namespace which my]] $setcmd]
      }
    }
  }
}

