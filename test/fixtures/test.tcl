set a 0
set b(a) 1
set b(b) 2
proc c args return
proc d {a {b 0}} {return $b}
proc e {} {}