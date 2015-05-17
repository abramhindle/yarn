reset
set size 1.8,1
set terminal postscript eps monochrome 22
set output "eventsovertime.eps"
set nox2tics
set noy2tics
set samples 1024

set xdata time
set timefmt "%Y-%m-%d"
set title "Important Postgresql Changes Over Time"

f(x) = a*x + b
#f(x) = a*x**2 + b*x + c
#g(x) = h*x*x + d*x + c
fit f(x) "./distance.plot" using 1:2 via a, b
#fit f(x) "./distance.plot" using 1:2 via a, b, c
#fit g(x) "./distance.plot" using 1:2 via h, d, c
#plot ["1996-01-01":"2006-01-01"] [0:1.3] "./distance.plot" using 1:2 smooth bezier, "./goodtimes.da" using 1:2 with impulses,f(x),g(x)
plot ["1996-01-01":"2006-01-01"] [0:1.3] "./distance.plot" using 1:2 title "Inverse Distance of a Change From a Filtered Change" , \
"./goodtimes.da" using 1:2 title "Important Change"  with impulses, \
f(x) title "Linear Best Fit"

