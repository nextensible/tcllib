set srcdir [file dirname [file normalize [file join [pwd] [info script]]]]
set moddir [file dirname $srcdir]

set version 1.2
set module dicttool
set filename dicttool
if {[file exists [file join $moddir .. practcl build doctool.tcl]]} {
  source [file join $moddir .. practcl build doctool.tcl]
} else {
  package require practcl 0.13
}
::practcl::doctool create AutoDoc

set fout [open [file join $moddir ${filename}.tcl] w]
dict set modmap %module% $module
dict set modmap %version% $version
dict set modmap %license% BSD
dict set modmap %filename% $filename

set authors {{Sean Woods} {<yoda@etoyoc.com>}}

puts $fout [string map $modmap {###
# %filename%.tcl
#
# Copyright (c) 2018 Sean Woods
#
# BSD License
###
# @@ Meta Begin
# Package %module% %version%
# Meta platform     tcl
# Meta summary      Enhancements to the dict command to support recursive merging
# Meta description  This package adds several list commands and dict commands which
# Meta description  developers find themselves implementing over and over again.
# Meta description  In addition it provides tools to manage recursive dicts in a
# Meta description  clean (and thoroughly regression tested) format.
# Meta category     dict
# Meta subject      dict
# Meta require      {Tcl 8.5}}]
foreach {name email} $authors {
  puts $fout   "# Meta author       $name"
}
puts $fout [string map $modmap {# Meta license      %license%
# @@ Meta End
}]

puts $fout [string map $modmap {###
# Amalgamated package for %module%
# Do not edit directly, tweak the source in build/ and rerun
# build.tcl
###
package provide %module% %version%
namespace eval ::%module% {}
}]


# Track what files we have included so far
set loaded {}
lappend loaded build.tcl test.tcl

# These files must be loaded in a particular order
foreach file {
  core.tcl
} {
  lappend loaded $file
  set content [::practcl::cat [file join $srcdir {*}$file]]
  AutoDoc scan_text $content
  puts $fout "###\n# START: [file tail $file]\n###"
  puts $fout [::practcl::docstrip $content]
  puts $fout "###\n# END: [file tail $file]\n###"
}
# These files can be loaded in any order
foreach file [lsort -dictionary [glob [file join $srcdir *.tcl]]] {
  if {[file tail $file] in $loaded} continue
  lappend loaded $file
  set content [::practcl::cat [file join $srcdir {*}$file]]
  AutoDoc scan_text $content
  puts $fout "###\n# START: [file tail $file]\n###"
  puts $fout [::practcl::docstrip $content]
  puts $fout "###\n# END: [file tail $file]\n###"
}

# Provide some cleanup and our final package provide
puts $fout [string map $modmap {
namespace eval ::%module% {
  namespace export *
}
}]
close $fout

###
# Build our pkgIndex.tcl file
###
set fout [open [file join $moddir pkgIndex.tcl] w]
puts $fout [string map $modmap {# Tcl package index file, version 1.1
# This file is generated by the "pkg_mkIndex" command
# and sourced either when an application starts up or
# by a "package unknown" script.  It invokes the
# "package ifneeded" command to set up package-related
# information so that packages will be loaded automatically
# in response to "package require" commands.  When this
# script is sourced, the variable $dir must contain the
# full path name of this file's directory.

if {![package vsatisfies [package provide Tcl] 8.5]} {return}
}]
puts $fout [string map $modmap {
package ifneeded %module% %version% [list source [file join $dir %module%.tcl]]
}]
close $fout

###
# Generate the test script
###
namespace eval ::clay {}
source [file join $srcdir core.tcl]
set fout [open [file join $moddir $filename.test] w]
puts $fout [source [file join $srcdir test.tcl]]
close $fout
set manout [open [file join $moddir $filename.man] w]
puts $manout [AutoDoc manpage map $modmap \
  header [::practcl::cat [file join $srcdir manual.txt]] \
  authors $authors \
  footer [::practcl::cat [file join $srcdir footer.txt]] \
]
close $manout
