/// Cleaning step
run("Clear Results");
roiManager("reset");
run("Remove Overlay");
setOption("ExpandableArrays", true);
run("Options...", "iterations=1 count=1 black do=Nothing");
run("Set Measurements...", "area mean standard min center bounding fit shape integrated skewness display redirect=None decimal=5");
//run("Select All");
close("\\Others");

/// Parameter setup

Dialog.create("SiCE Root hair macro");
	Dialog.addNumber("Min Root hair size",10, 1,5, "pixels^2");
	Dialog.addNumber("Rolling background size",200, 1,5, " ");
	Dialog.addNumber("Mean Threshold",9000, 0,6, " ");
	Dialog.addNumber("Std Threshold",3500, 0,5, " ");
	Dialog.addCheckbox("Manual Main root check?", false);
	Dialog.addCheckbox("Manual RH removal?", false);
	Dialog.addCheckbox("Batch mode?", false);
	Dialog.addCheckbox("First bulge?", false);
	Dialog.show();
	minsize=Dialog.getNumber();
	bck=Dialog.getNumber();
	MeanT = Dialog.getNumber();
	StdDevT = Dialog.getNumber();
	rootCheck=Dialog.getCheckbox();
	remov=Dialog.getCheckbox();
	batch=Dialog.getCheckbox();
	bulge=Dialog.getCheckbox();
	

	
/// Result table
	title1 = "[Result summary:]"; 
	f=title1; 
	run("New... ", "name="+title1+"type=Table");
	print(f,"\\Headings: Image name \t Root Hair nb \t Distance from Root tip \t Length \t Out of Focus \t Branched \t X centroid \t Y centroid");
	title3 = "[Density summary:]"; 
	h=title3; 
	run("New... ", "name="+title3+"type=Table");
	print(h,"\\Headings: Image name \t RH nb  \t Root length \t density");
	
if (bulge== true){ 
	title2 = "[Bulge summary:]"; 
	g=title2; 
	run("New... ", "name="+title2+"type=Table");
	print(g,"\\Headings: Image name \t Distance from Root tip");
}


/// Folder selection

if (batch== true){ 
	dir1 = getDirectory("Choose Source Directory ");
	list = getFileList(dir1);
	for (i=0; i<list.length; i++) {
		if (endsWith(list[i], ".tif")) {
	open(dir1+list[i]);
	title=getTitle();
	RootHairMacro(minsize, bck, MeanT, remov, f,rootCheck);	
	roiManager("Save", dir1+title+".zip");
	
/// First bulge measure	
	if (bulge== true){ 
	run("Clear Results");
	roiManager("Deselect");
	roiManager("Show None");
	run("Select None");
/// Zoom in	
	roiManager("select", roiManager("count")-1);
	getSelectionCoordinates(xpoints, ypoints);
	X=xpoints[0]; 
	Y=ypoints[0]-150; 
	run("Set... ", "zoom=200 x="+X+" y="+Y+"");
	run("Select None");
	setTool("multipoint");
	
    waitForUser("select first Bulge");
    IsROI=selectionType();
    if (IsROI ==-1) {
    	print(g,title+"\t ND ");	
    }
    else {
    getSelectionCoordinates(xpoints, ypoints);
	roiManager("Select",roiManager("count")-1);
	roiManager("Measure");
	print(g,title+"\t"+sqrt(pow((getResult("X", 0)-xpoints[0]),2)+pow((getResult("Y", 0)-ypoints[0]),2)));
    }
	}
	
	close("*");
	}
	}
	}
else {
	RootHairMacro(minsize, bck, MeanT, remov, f,rootCheck); 
}
	
	
function RootHairMacro(minsize, bck, MeanT, remov, f,rootCheck) { 
// function description
	
	run("Clear Results");
	roiManager("reset");
	run("Select None");
	
	/// Root segmentation
	
		setBatchMode(true);
		title=getTitle();
		run("Invert");
		run("Duplicate...", " ");
		run("Subtract Background...", "rolling="+bck+"");	
		RootSegment(title, rootCheck);
		
	/// Root skeleton
	
		run("Skeletonize (2D/3D)");
		run("Select None");
		run("Analyze Skeleton (2D/3D)", "prune=[shortest branch] calculate show  exclude calculate");
		close("Trace");
		selectWindow("Longest shortest paths");
		rename("Trace");
		setThreshold(8, 245);
		setOption("BlackBackground", true);
		run("Convert to Mask");
		run("Dilate");
		run("Dilate");
		run("Skeletonize (2D/3D)");
		run("Analyze Skeleton (2D/3D)", "prune=[shortest branch] calculate show exclude calculate");
		IJ.renameResults("Branch information","Results");
		RootLength= getResult("Branch length",0);
		if (getResult("V2 y",0)>getResult("V1 y",0)) {
			tipX=getResult("V2 x",0);
			tipY=getResult("V2 y",0);
		}
		else {
			tipX=getResult("V1 x",0);
			tipY=getResult("V1 y",0);
		}
	
		close("Trace");
		setThreshold(2, 200);
		setOption("BlackBackground", true);
		run("Convert to Mask");
		run("Analyze Particles...", "size=300-Infinity display add");
		roiManager("select", 1);
		roiManager("rename", "Root skeleton");
		
	/// Filtering & Root hair segmentation

		selectWindow(title);
		run("Duplicate...", " ");
		rename("Temp");
	/// DoG	
		run("Top Hat...", "radius=2");
		run("Duplicate...", " ");
		rename("Output");
		setAutoThreshold("Otsu dark");
		run("Convert to Mask");
		roiManager("Select", 0);
	//	run("Enlarge...", "enlarge=1 pixel");
		run("Fill", "slice");
		run("Select None");
		run("Wand Tool...", "tolerance=2 mode=4-connected");
		doWand(0, 0);
		run("Clear");
		run("Select None");
		roiManager("Select", 0);
		run("Clear", "slice");
		roiManager("deselect");
		run("Fill Holes");
		makeOval(tipX-50, tipY-50, 100, 100);	
		run("Clear", "slice");
		run("Select None");
		run("Analyze Particles...", "size="+minsize+"-Infinity display exclude add");
		run("Select All");
		run("Clear", "slice");
		
		if (remov==true)
			{
	for (k =  roiManager("count")-1 ; k >1 ; k--) {
	setBatchMode("exit and display");
		selectWindow("Temp");
		roiManager("Show None");
		roiManager("select", k);
		Dialog.create("RHair OK?");
		Dialog.addCheckbox("OK?", true);
		Dialog.show();
		trueRH=Dialog.getCheckbox();
		if (trueRH==false) {
		roiManager("Delete");
		}

	}
	setBatchMode(true);
			}
		
/// Arrays creation for measurements		
		count = roiManager("count");
		OOF = newArray(count-2);
		Dist = newArray(count-2);
		Length = newArray(count-2);
		Branch = newArray(count-2);
		Xcent = newArray(count-2);
		Ycent = newArray(count-2);
		
	selectWindow("Temp");
	RHfiltering(OOF,Dist,Length,MeanT,Xcent, Ycent);
	Newcount = roiManager("count");
	selectWindow("Output");
	
	if (count>2) {	
		array = newArray(count-2);
	  for (j=0; j<array.length; j++) {
	      array[j] = j+2;
	    }
	  Filtarray = newArray(Newcount-count);
	  for (l=0; l<Filtarray.length; l++) {
	      Filtarray[l] = l+count;
	    }
			roiManager("select", array);
			roiManager("Combine");
			roiManager("add");
			run("Fill", "slice");
			roiManager("deselect");	
			roiManager("select", roiManager("count")-1);
			roiManager("rename", "All_Root_Hairs");
			roiManager("deselect");	
			run("Skeletonize (2D/3D)");

	for (n=0; n<count-2; n++) {
		selectWindow("Output");
		roiManager("select", n+2);
		run("Duplicate...", " ");
		run("Analyze Skeleton (2D/3D)", "prune=[shortest branch] calculate show exclude calculate");
		Branch[n]= "No";
	    Length[n] = getResult("Longest Shortest Path", 0);
	    if (getResult("# Branches", 0)>1) {
	    Branch[n]= "Yes";	
	    }
	    Array.getStatistics(Dist, min, Distmax, mean, stdDev);
	print(f,title+"\t"+(n+1)+"\t"+Dist[n]+"\t"+Length[n]+"\t"+OOF[n]+"\t"+Branch[n]+"\t"+Xcent[n]+"\t"+Ycent[n]);
	print(h,title+"\t"+count-2+"\t"+Distmax+"\t"+count-2/Distmax);
	run("Clear Results");
	close("Branch information");
	close("Longest shortest paths");
	close("Tagged skeleton");
	close("Temp-2");
	    }
	    roiManager("select", Filtarray);
		roiManager("Combine");
		roiManager("add");
		roiManager("select", roiManager("count")-1);
		roiManager("rename", "Selected_Root_Hairs");
		print(h,title+"\t"+count-2+"\t"+RootLength+"\t"+count-2/RootLength);
	    }
	    else {
	print(f,title+"\t No Root hairs\t ND \t ND \t ND \t ND \t ND \t ND"); 
	print(h,title+"\t"+0+"\t"+RootLength+"\t ND");
	    }
	selectWindow(title);
	close("\\Others");
	roiManager("Deselect");
	makePoint(tipX, tipY, "medium red hybrid");
	roiManager("Add");
	roiManager("select", roiManager("count")-1);
	roiManager("rename", "Tip");
	setBatchMode(false);
	}
	
function RHfiltering(OOF,Dist,Length,MeanT,Xcent,Ycent) {
	run("Clear Results");
	count = roiManager("count");	
	run("Clear Results");
	for (m = 0; m < count-2; m++) {
	selectWindow("Temp");
	roiManager("Show None");
	roiManager("select", m+2);
	roiManager("rename", "RH-"+m+1);
	run("Measure");
	MeanRH= getResult("Mean", 0);
	Xcent[m]= getResult("XM", 0);
	Ycent[m]= getResult("YM", 0);
	ratio=getResult("Mean", 0)/getResult("StdDev", 0);
	if (ratio<3 || MeanRH<MeanT) {
		OOF[m]="Out of Focus";
	}
	else {
		OOF[m]="In Focus";
		roiManager("add");
		roiManager("select", roiManager("count")-1);
		roiManager("rename", "RH"+m+1+"-Filtered");
	}
	
	print("RH "+m+1+" "+OOF[m]);
	print("SD:"+getResult("StdDev", 0));
	print("Mean:"+getResult("Mean", 0));
	print("Ratio:"+ratio);
	selectWindow("Longest shortest paths");
	run("Select All");
	run("Clear", "slice");
	getDimensions(width, height, channels, slices, frames);
	makeRectangle(0, Ycent[0], width, height);
	roiManager("Select", 1);
	setForegroundColor(255, 255, 255);
	run("Draw", "slice");
	makeRectangle(0, Ycent[m], width, height);
	run("Clear Outside");
	run("Skeletonize (2D/3D)");
	run("Analyze Skeleton (2D/3D)", "prune=[shortest branch] calculate show");
	IJ.renameResults("Branch information","Results");
	Dist[m]=getResult("Branch length", 0);
	print("Distance From Root tip:"+Dist[m]);
	close();
	run("Clear Results");
	}
		}
	
function RootSegment(title,rootCheck){
	getDimensions(width, height, channels, slices, frames);
//	selectImage(title);
	run("Duplicate..."," ");
	rename("tempBis");
	setAutoThreshold("Default dark");
	run("Convert to Mask");
	run("Dilate");
	run("Dilate");
	run("Fill Holes");
	run("Erode");
	run("Erode");
	makeRectangle(0, 0, width, 5);
	run("Draw", "slice");
	run("Select None");
	run("Fill Holes");
	makeRectangle(0, 0, width, 5);
	run("Clear", "slice");
	run("Select None");
	run("Distance Map");
	run("Variance...", "radius=5");
	setAutoThreshold("Otsu dark");
	run("Convert to Mask");
	run("Fill Holes");
	run("Analyze Particles...", "size=5000-Infinity display clear add ");
	roiManager("select", 0);
//	run("Enlarge...", "enlarge=15");
	roiManager("Update");
	run("Clear Outside");
	run("Fill");
if (rootCheck==true)
			{	
setBatchMode("exit and display");
setTool("wand");
waitForUser("Check main root");
roiManager("reset");
roiManager("add");
setBatchMode(true);
	}
	roiManager("select", 0);
	roiManager("rename", "Root");
}


