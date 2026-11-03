run("Clear Results");
roiManager("reset");
run("Z Project...", "projection=[Sum Slices]");
rename("Result");
run("Duplicate...", "Nuclei");
rename("Nuclei");
run("Duplicate...", "tmp");

setAutoThreshold("Default dark");
//setThreshold(50, 678);
//run("Threshold...");
waitForUser("Select threshold");
run("Convert to Mask");
setBatchMode(true);
run("Distance Map");
run("Find Maxima...", "noise=1 output=[Single Points]");

run("Analyze Particles...", "  show=[Count Masks] clear");
run("Random LUT");
rename("seedCount");
close("mask-1");
close("mask-1 Maxima");
selectWindow("Result");
run("Find Edges");

// Marker based watershed
run("Marker-controlled Watershed", "input=Result marker=seedCount mask=None calculate use");

rename("Lower");
run("Duplicate...", "tmp");
rename("higher");
getRawStatistics(nPixels, mean, min, max, std, histogram);
pix1=getPixel(1,1);
pix2=getPixel(0,0);
selectWindow("Lower");
setThreshold(0, pix1);
run("Convert to Mask");
run("Invert");
selectWindow("higher");
setThreshold(pix1, 200);
run("Convert to Mask");
run("Invert");
imageCalculator("Add create", "higher","Lower");
run("Analyze Particles...", "size=3-Infinity show=[Count Masks] display clear add");
selectWindow("Nuclei");
run("8-bit");
roiManager("Show All");
run("Set Measurements...", "area mean integrated redirect=None decimal=3");

roiManager("multi-measure");

close("Lower");
close("Higher");
close("result");
close("Result of higher");
close("seedCount");
close("Nuclei-1");
close("Nuclei-1 Maxima");
close("Count Masks of Result of higher");

setBatchMode(false);