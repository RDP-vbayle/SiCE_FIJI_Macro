//// Macro for Mature Cleared Arabidopsis Seed size semi automatic measuremesnt. INPUT: Folder containing brightfield images
//// Distance Transform Watershed plugin needed https://imagej.net/plugins/distance-transform-watershed
/// Reset

setOption("BlackBackground", true);
run("Clear Results");
roiManager("reset");
run("Options...", "iterations=1 count=1 black");

dir1 = getDirectory("Choose Source Directory ");
list = getFileList(dir1);
Dialog.create("Parameters:");
Dialog.addCheckbox("  Reference image?", false);
Dialog.addNumber("		Known distance",10);
Dialog.addChoice("		Unit", newArray("µm", "mm", "cm"));
Dialog.addMessage("Scale:") 
Dialog.addNumber("		Distance in pixels",0.406);
Dialog.addNumber("		Known distance",1);
Dialog.addNumber("		Pixel ",1);
Dialog.addChoice("		Unit", newArray("µm", "mm", "cm"));
Dialog.addNumber("		Background value", 3200);
Dialog.addNumber("Min Seed Size (units^2)",30000);
Dialog.addNumber("Max Seed Size (units^2)", 200000);
Dialog.show();
ref=Dialog.getCheckbox();
rule = Dialog.getNumber();
Unitbis = Dialog.getChoice();
distance = Dialog.getNumber();
known = Dialog.getNumber();
pixel = Dialog.getNumber();
Unit = Dialog.getChoice();
noiz= Dialog.getNumber();
minSize = Dialog.getNumber();
maxSize = Dialog.getNumber();

if (ref== true)
{
	open();
	setTool("line");
	waitForUser("draw a line for scaling ("+rule+" "+Unitbis+")");
	run("Measure");
	distance = getResult("Length",0);
	known = rule;
	Unit = Unitbis;
	run("Set Scale...", "distance="+distance+" known="+known+" pixel="+pixel+" unit="+Unit+" global");
	run("Close All");
	run("Clear Results");
}

	title1 = "[Result summary:]";  
	f=title1; 
	run("New... ", "name="+title1+" type=Table");
	print(f,"\\Headings:Photo\tSeed number\tSeed Area "+Unit+"^2\tMajor axis "+Unit+"\tMinor axis "+Unit+"");
	NewDir= dir1+ "Analysed" +File.separator;
    File.makeDirectory(NewDir); 

setBatchMode(true);	
	for (i=0; i<list.length; i++) {
	    showProgress(i+1, list.length);
	    open(dir1+list[i]);
		run("Clear Results");
		run("Set Measurements...", "area mean fit shape redirect=None decimal=3");
		roiManager("reset");
		title=getTitle();
		
		run("Set Scale...", "distance="+distance+" known="+known+" pixel="+pixel+" unit="+Unit+" global");
		getDimensions(width, height, channels, slices, frames);	
///Seed segmentation
	title=getTitle();
	run("Duplicate...", "title=temp duplicate");
//split channel & LUT
	run("Split Channels");
	selectWindow("C1-temp");
	close();
	selectWindow("C2-temp");
	close();
	selectWindow("C3-temp");	
	run("Invert");
////methode watershed
	setBatchMode("show");
//noise removal

	run("Subtract...", "value="+noiz);
//filtering
	selectWindow("C3-temp");
//threshold
	setAutoThreshold("Otsu dark");
	run("Convert to Mask");
	run("Fill Holes");

//Distance transform watershed
	run("Distance Transform Watershed", "distances=[Borgefors (3,4)] output=[16 bits] normalize dynamic=4 connectivity=4");
	setThreshold(1, 65535);
	run("Convert to Mask");
	run("Erode");
// border eclusion
	makeRectangle(2, 2, width-4, height-4);
	run("Make Inverse");
	fill();
	run("Select None");
// Analyse Particle		
	run("Analyze Particles...", "size="+minSize+"-"+maxSize+" circularity=0.1-1.00 show=Outlines display exclude clear summarize add");
	close("C1-temp");
	close("Drawing of C1-temp");
			selectWindow(title);
	run("From ROI Manager");

	saveAs("TIFF", NewDir+ title+ " analysed");
	selectWindow("Summary");
	lines = split(getInfo(), "\n");
	headings = split(lines[0], "\t");
	values = split(lines[1], "\t");
	nbROI= parseInt(values[1]);
			
		    for(l=0; l<=nbROI-1; l++)
						{
					Area = getResult("Area",l);
					Minor = getResult("Minor",l);
					Major = getResult("Major",l);
					print(f, title+"\t"+l+1+"\t"+ Area  +"\t"+ Major+"\t"+ Minor);
					}
	close("Summary");
	run("Close All");	
	}		
		setBatchMode(false);

		selectWindow("Result summary:");