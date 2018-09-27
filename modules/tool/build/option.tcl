###
# topic: 68aa446005235a0632a10e2a441c0777
# title: Define an option for the class
###
proc ::tool::define::option {name args} {
  set class [current_class]
  set dictargs {default {}}
  foreach {var val} [::oo::meta::args_to_dict {*}$args] {
    dict set dictargs [string trim $var -:/] $val
  }
  set name [string trimleft $name -]

  ###
  # Option Class handling
  ###
  set optclass [dict getnull $dictargs class]
  if {$optclass ne {}} {
    foreach {f v} [::oo::meta::info $class getnull option_class $optclass] {
      if {![dict exists $dictargs $f]} {
        dict set dictargs $f $v
      }
    }
    if {$optclass eq "variable"} {
      variable $name [dict getnull $dictargs default]
    }
  }
  foreach {f v} $dictargs {
    $class clay set option $name $f $v
  }
}

###
# topic: 827a3a331a2e212a6e301f59c1eead59
# title: Define a class of options
# description:
#    Option classes are a template of properties that other
#    options can inherit.
###
proc ::tool::define::option_class {name args} {
  set class [current_class]
  set dictargs {default {}}
  set name [string trimleft $name -]
  foreach {f v} [::oo::meta::args_to_dict {*}$args] {
    $class clay set option_class $name [string trim $f -/] $v
  }
}

::tool::define ::tool::object {
  property options_strict 0
  variable organs {}

  option_class organ {
    widget label
    set-command {my graft %field% %value%}
    get-command {my organ %field%}
  }

  option_class variable {
    widget entry
    set-command {my variable %field% ; set %field% %value%}
    get-command {my variable %field% ; set %field%}
  }

  dict_ensemble config config {
    get {
      return [my Config_get {*}$args]
    }
    merge {
      return [my Config_merge {*}$args]
    }
    set {
      my Config_set {*}$args
    }
  }

  ###
  # topic: 86a1b968cea8d439df87585afdbdaadb
  ###
  method cget args {
    return [my Config_get {*}$args]
  }

  ###
  # topic: 73e2566466b836cc4535f1a437c391b0
  ###
  method configure args {
    # Will be removed at the end of "configurelist_triggers"
    set dictargs [::oo::meta::args_to_options {*}$args]
    if {[llength $dictargs] == 1} {
      return [my cget [lindex $dictargs 0]]
    }
    set dat [my Config_merge $dictargs]
    my Config_triggers $dat
  }

  method Config_get {field args} {
    my variable config option_canonical option_getcmd
    set field [string trimleft $field -]
    if {[info exists option_canonical($field)]} {
      set field $option_canonical($field)
    }
    if {[info exists option_getcmd($field)]} {
      return [eval $option_getcmd($field)]
    }
    if {[dict exists $config $field]} {
      return [dict get $config $field]
    }
    if {[llength $args]} {
      return [lindex $args 0]
    }
    return [my meta cget $field]
  }

  ###
  # topic: dc9fba12ec23a3ad000c66aea17135a5
  ###
  method Config_merge dictargs {
    my variable config option_canonical
    set rawlist $dictargs
    set dictargs {}
    set dat [my clay get option]
    foreach {field val} $rawlist {
      set field [string trim $field -:/]
      if {[info exists option_canonical($field)]} {
        set field $option_canonical($field)
      }
      dict set dictargs $field $val
    }
    ###
    # Validate all inputs
    ###
    foreach {field val} $dictargs {
      set script [dict getnull $dat $field validate-command]
      if {$script ne {}} {
        dict set dictargs $field [eval [string map [list %field% [list $field] %value% [list $val] %self% [namespace which my]] $script]]
      }
    }
    ###
    # Apply all inputs with special rules
    ###
    foreach {field val} $dictargs {
      set script [dict getnull $dat $field set-command]
      dict set config $field $val
      if {$script ne {}} {
        {*}[string map [list %field% [list $field] %value% [list $val] %self% [namespace which my]] $script]
      }
    }
    return $dictargs
  }

  method Config_set args {
    set dictargs [::tool::args_to_options {*}$args]
    set dat [my Config_merge $dictargs]
    my Config_triggers $dat
  }

  ###
  # topic: 543c936485189593f0b9ed79b5d5f2c0
  ###
  method Config_triggers dictargs {
    set dat [my meta getnull option]
    foreach {field val} $dictargs {
      set script [dict getnull $dat $field post-command:]
      if {$script ne {}} {
        {*}[string map [list %field% [list $field] %value% [list $val] %self% [namespace which my]] $script]
      }
    }
  }

  method Option_Default field {
    set info [my meta getnull option $field]
    set getcmd [dict getnull $info default-command:]
    if {$getcmd ne {}} {
      return [{*}[string map [list %field% $field %self% [namespace which my]] $getcmd]]
    } else {
      return [dict getnull $info default:]
    }
  }
}

package provide tool::option 0.1
