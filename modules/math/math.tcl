# math.tcl --
#
#	Collection of math functions.
#
# Copyright (c) 1998-2000 by Ajuba Solutions.
#
# See the file "license.terms" for information on usage and redistribution
# of this file, and for a DISCLAIMER OF ALL WARRANTIES.
# 
# RCS: @(#) $Id: math.tcl,v 1.5 2000/06/15 23:46:45 ericm Exp $

package provide math 1.0

namespace eval ::math {
}

# ::math::cov --
#
#	Return the coefficient of variation of three or more values
#
# Arguments:
#	val1	first value
#	val2	second value
#	args	other values
#
# Results:
#	cov	coefficient of variation expressed as percent value

proc ::math::cov {val1 val2 args} {
     set sum [ expr { $val1+$val2 } ]
     set N [ expr { [ llength $args ] + 2 } ]
     foreach val $args {
        set sum [ expr { $sum+$val } ]
     }
     set mean [ expr { $sum/$N } ]
     set sigma_sq 0
     foreach val [ concat $val1 $val2 $args ] {
        set sigma_sq [ expr { $sigma_sq+pow(($val-$mean),2) } ]
     }
     set sigma_sq [ expr { $sigma_sq/($N-1) } ] 
     set sigma [ expr { sqrt($sigma_sq) } ]
     set cov [ expr { ($sigma/$mean)*100 } ]
     set cov
}

# ::math::integrate --
#
#	calculate the area under a curve defined by a set of (x,y) data pairs.
#	the x data must increase monotonically throughout the data set for the 
#	calculation to be meaningful, therefore the monotonic condition is
#	tested, and an error is thrown if the x value is found to be
#	decreasing.
#
# Arguments:
#	xy_pairs	list of x y pairs (eg, 0 0 10 10 20 20 ...); at least 5
#			data pairs are required, and if the number of data
#			pairs is even, a padding value of (x0, 0) will be
#			added.
# 
# Results:
#	result		A two-element list consisting of the area and error
#			bound (calculation is "Simpson's rule")

proc ::math::integrate { xy_pairs } {
     
     set length [ llength $xy_pairs ]
     
     if { $length < 10 } {
        return -code error "at least 5 x,y pairs must be given"
     }   
     
     ;## are we dealing with x,y pairs?
     if { [ expr $length % 2 ] } {
        return -code error "unmatched xy pair in input"
     }
     
     ;## are there an even number of pairs?  Augment.
     if { ! [ expr $length % 4 ] } {
        set xy_pairs [ concat [ lindex $xy_pairs 0 ] 0 $xy_pairs ]
     }
     set x0   [ lindex $xy_pairs 0     ]
     set x1   [ lindex $xy_pairs 2     ]
     set xn   [ lindex $xy_pairs end-1 ]
     set xnminus1 [ lindex $xy_pairs end-3 ]
    
     if { $x1 < $x0 } {
        return -code error "monotonicity broken by x1"
     }

     if { $xn < $xnminus1 } {
        return -code error "monotonicity broken by xn"
     }   
     
     ;## handle the assymetrical elements 0, n, and n-1.
     set sum [ expr {[ lindex $xy_pairs 1 ] + [ lindex $xy_pairs end ]} ]
     set sum [ expr {$sum + (4*[ lindex $xy_pairs end-2 ])} ]

     set data [ lrange $xy_pairs 2 end-4 ]
     
     set xmax $x1
     set i 1
     foreach {x1 y1 x2 y2} $data {
        incr i
        if { $x1 < $xmax } {
           return -code error "monotonicity broken by x$i"
        }
        set xmax $x1
        incr i
        if { $x2 < $xmax } {
           return -code error "monotonicity broken by x$i"
        }
        set xmax $x2
        set sum [ expr {$sum + (4*$y1) + (2*$y2)} ]
     }   
     
     if { $xmax > $xnminus1 } {
        return -code error "monotonicity broken by xn-1"
     }   
    
     set h [ expr { ( $xn - $x0 ) / $i } ]
     set area [ expr { ( $h / 3.0 ) * $sum } ]
     set err_bound  [ expr { ( ( $xn - $x0 ) / 180.0 ) * pow($h,4) * $xn } ]  
     return [ list $area $err_bound ]
}

# ::math::max --
#
#	Return the maximum of two or more values
#
# Arguments:
#	val	first value
#	args	other values
#
# Results:
#	max	maximum value

proc ::math::max {val args} {
    set max $val
    foreach val $args {
	if { $val > $max } {
	    set max $val
	}
    }
    set max
}

# ::math::mean --
#
#	Return the mean of two or more values
#
# Arguments:
#	val	first value
#	args	other values
#
# Results:
#	mean	arithmetic mean value

proc ::math::mean {val args} {
    set sum $val
    set N [ expr { [ llength $args ] + 1 } ]
    foreach val $args {
        set sum [ expr { $sum + $val } ]
    }
    set mean [expr { double($sum) / $N }]
}

# ::math::min --
#
#	Return the minimum of two or more values
#
# Arguments:
#	val	first value
#	args	other values
#
# Results:
#	min	minimum value

proc ::math::min {val args} {
    set min $val
    foreach val $args {
	if { $val < $min } {
	    set min $val
	}
    }
    set min
}

# ::math::product --
#
#	Return the product of one or more values
#
# Arguments:
#	val	first value
#	args	other values
#
# Results:
#	prod	 product of multiplying all values in the list

proc ::math::product {val args} {
    set prod $val
    foreach val $args {
        set prod [ expr { $prod*$val } ]
    }
    set prod
}

# ::math::sigma --
#
#	Return the standard deviation of three or more values
#
# Arguments:
#	val1	first value
#	val2	second value
#	args	other values
#
# Results:
#	sigma	population standard deviation value

proc ::math::sigma {val1 val2 args} {
     set sum [ expr { $val1+$val2 } ]
     set N [ expr { [ llength $args ] + 2 } ]
     foreach val $args {
        set sum [ expr { $sum+$val } ]
     }
     set mean [ expr { $sum/$N } ]
     set sigma_sq 0
     foreach val [ concat $val1 $val2 $args ] {
        set sigma_sq [ expr { $sigma_sq+pow(($val-$mean),2) } ]
     }
     set sigma_sq [ expr { $sigma_sq/($N-1) } ] 
     set sigma [ expr { sqrt($sigma_sq) } ]
     set sigma
}     

# ::math::stats --
#
#	Return the mean, standard deviation, and coefficient of variation as
#	percent, as a list.
#
# Arguments:
#	val1	first value
#	val2	first value
#	args	all other values
#
# Results:
#	{mean stddev coefvar}

proc ::math::stats {val1 val2 args} {
     set sum [ expr { $val1+$val2 } ]
     set N [ expr { [ llength $args ] + 2 } ]
     foreach val $args {
        set sum [ expr { $sum+$val } ]
     }
     set mean [ expr { $sum/$N } ]
     set sigma_sq 0
     foreach val [ concat $val1 $val2 $args ] {
        set sigma_sq [ expr { $sigma_sq+pow(($val-$mean),2) } ]
     }
     set sigma_sq [ expr { $sigma_sq/($N-1) } ] 
     set sigma [ expr { sqrt($sigma_sq) } ]
     set cov [ expr { ($sigma/$mean)*100 } ]
     return [ list $mean $sigma $cov ]
}

# ::math::sum --
#
#	Return the sum of one or more values
#
# Arguments:
#	val	first value
#	args	all other values
#
# Results:
#	sum	arithmetic sum of all values in args

proc ::math::sum {val args} {
    set sum $val
    foreach val $args {
        set sum [ expr { $sum+$val } ]
    }
    set sum
}

