set terminal png
unset xtics
set output "/tmp/garbagemap/".time."_".table."_heatmap.png"
set title "Heat Map (".table.":".range.")"
set yrange [0:ymax] reverse
set ylabel "Range Number"
plot infile matrix with image
