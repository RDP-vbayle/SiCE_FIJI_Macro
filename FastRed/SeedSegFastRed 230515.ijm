////// Macro for FastRed seeds segregation analysis. Script by Vincent Bayle May 23

/// watch out tif names BF image should follow fluo image ex: 1403-1-01.tif, 1403-1-01_BF.tif
/// use 01 for file nb 1 instead of 1 only ex: 1403-01.tif and not 1403-1.tif
/// if you want to check image by image what's going on: add // line 13 and remove // in lines 67 to 69


/// Reset section
run("Clear Results");
roiManager("reset");
run("Remove Overlay");
setOption("ExpandableArrays", true);
run("Set Measurements...", "area mean centroid center bounding fit shape feret's stack redirect=None decimal=3");
setBatchMode(true);	

/// Parameters
range= 0.05; //range for ratio (by default: 0.75+-0.05 
bck= 200; // rolling background for BF
min= 500; //min seed size in pixels
thr=  3; // signal for FastRed positive detection (by default 3* background intensity

///Input Directory
dir1 = getDirectory("Choose Directory for BF");
list1 = getFileList(dir1);
direct = File.getParent(dir1);
///Creation du tableau de résultat
	title1 = "[Transformant segregation Result:]"; 
	f=title1; 
	run("New... ", "name="+title1+" type=Table");

	print(f,"\\Headings: Image name \t seed nb \t Positive seed \t Ratio (expected 0.75) \t Insertion type");

/// Ouverture des images+ debut de boucle

for (m=0; m<list1.length; m++) {
					
				showProgress(m+1, list1.length);
				
///Seed segmentation
//split channel & LUT
	open(dir1+list1[m]);
	name=getTitle();
	rename("Fluo");
	open(dir1+list1[m+1]);
	run("8-bit");
	rename("BF");
	run("Invert");
//noise removal BF
	run("Subtract Background...", "rolling="+bck);
//filtering

//threshold BF
	setAutoThreshold("Minimum dark");
	run("Convert to Mask");
	run("Fill Holes");
	run("Erode");

//Distance transform watershed BF
	run("Distance Transform Watershed", "distances=[Borgefors (3,4)] output=[16 bits] normalize dynamic=3 connectivity=8");
	setThreshold(1, 65535);
	run("Convert to Mask");
	run("Erode");
// Analyse Particle	BF	
	run("Analyze Particles...", "size="+min+"-"+3*min+"circularity=0.5-1.00 show=Outlines add");
	SeedNb=roiManager("count");
	selectWindow("Fluo");
	run("16-bit");
	roiManager("Combine");
//run("Tile");
//waitForUser("");
//selectWindow("Fluo");
	run("Make Inverse");
	run("Measure");
	background=getResult("Mean", 0);
	run("Clear Results");
	Positiv=0;
	for (j = 0; j < SeedNb; j++) {
		roiManager("select", j);
		run("Measure");
		if (getResult("Mean", j)>=	background*thr) {
		Positiv=Positiv+1;	
		}
		}
// Results	
	selectWindow("BF");
	roiManager("Show All");
	close("\\Others");
	ratio=Positiv/SeedNb;
	if (ratio<=0.75+range && ratio>=0.75-range) {
		sgl="Single insertion";
	}
	if (ratio>=0.75+range) {
		sgl="several insertions";
	}
	if (ratio<=0.65+range && ratio>=0.65-range)  {
		sgl="Single insertion embryo lethals";
	}
	if (ratio<=0.5+range && ratio>=0.5-range)  {
		sgl="Single insertion gametophyte lethals";
	}
	if (ratio<=0.5-range) {
		sgl="Are these really transgenics?";
	}

	print(f, name+"\t"+ SeedNb +"\t"+ Positiv +"\t"+Positiv/SeedNb+"\t"+sgl);
	close("*");
	run("Clear Results");
	roiManager("reset");
	m=m+1;
	}
