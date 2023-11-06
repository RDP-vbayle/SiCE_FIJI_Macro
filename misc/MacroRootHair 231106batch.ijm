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
	Dialog.addNumber("Min Root hair size",140, 1,5, "pixels^2");
	Dialog.addNumber("Mean filtering size for Main root segmentation",10, 1,5, "pixels");
	Dialog.addNumber("Rolling background size",200, 1,5, " ");
	Dialog.addNumber("TopHat filter size for Root hair segmentation",5, 1,3, " ");
	Dialog.addNumber("Ratio between Mean Main Root fluo / Root hair fluorescence",1.2, 1,3, " ");
	Dialog.addCheckbox("Manual RH removal?", false);
	Dialog.addCheckbox("Batch mode?", false);
	Dialog.show();
	minsize=Dialog.getNumber();
	MedianFilt=Dialog.getNumber();
	bck=Dialog.getNumber();
	TopHat = Dialog.getNumber();
	ratio = Dialog.getNumber();
	remov=Dialog.getCheckbox();
	batch=Dialog.getCheckbox();
	
/// Result table
	title1 = "[Result summary:]"; 
	f=title1; 
	run("New... ", "name="+title1+"type=Table");
	print(f,"\\Headings: Image name \t Root Hair nb \t Distance from Root tip \t Length \t Out of Focus \t Branched \t X centroid \t Y centroid");

/// Folder selection

if (batch== true){ 
	dir1 = getDirectory("Choose Source Directory ");
	list = getFileList(dir1);
	for (i=0; i<list.length; i++) {
		if (endsWith(list[i], ".nd2")) {
	open(dir1+list[i]);
	title=getTitle();
	RootHairMacro(minsize, MedianFilt, bck, TopHat, ratio, remov, f);
	roiManager("Save", dir1+title+".zip");
	close("*");
	}
	}
	}
else {
	RootHairMacro(minsize, MedianFilt, bck, TopHat, ratio, remov, f); 
}
	
	
function RootHairMacro(minsize, MedianFilt, bck, TopHat, ratio, remov, f) { 
// function description
	
	run("Clear Results");
	roiManager("reset");
	
	/// Root segmentation
	
		setBatchMode(true);
		title=getTitle();
		run("Duplicate...", " ");
		run("Subtract Background...", "rolling="+bck+"");
		run("Median...", "radius="+MedianFilt+"");
		setAutoThreshold("Otsu dark");
		setOption("BlackBackground", true);
		run("Convert to Mask");
		run("Fill Holes");
		ErodeDilate(1);
		run("Analyze Particles...", "display add");
		
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
		run("Analyze Particles...", "display add");
		
	/// Filtering & Root hair segmentation
	
		selectWindow(title);
		run("Duplicate...", " ");
		rename("TopHat");
		run("Subtract Background...", "rolling="+bck+"");
		run("Top Hat...", "radius="+TopHat+"");
		run("Duplicate...", " ");
		setAutoThreshold("Triangle dark");
		run("Convert to Mask");
	ErodeDilate(2);
		roiManager("Select", 0);
		run("Fill", "slice");
		run("Select None");
		run("Wand Tool...", "tolerance=2 mode=4-connected");
		doWand(0, 0);
		run("Clear");
		run("Select None");
		roiManager("Select", 0);
		run("Enlarge...", "enlarge=1 pixel");
		run("Clear", "slice");
		roiManager("deselect");
		run("Select All");
		run("Select None");
		run("Analyze Particles...", "size="+minsize+"-Infinity display exclude add");
		if (remov==true)
			{
		waitForUser("Remove out Of Focus and aberrent ROIs in manager");
			}
		run("Select All");
		run("Clear", "slice");
		
/// Arrays creation for measurements		
		count = roiManager("count");
		OOF = newArray(count-2);
		Dist = newArray(count-2);
		Length = newArray(count-2);
		Branch = newArray(count-2);
		Xcent = newArray(count-2);
		Ycent = newArray(count-2);
		
	selectWindow("TopHat");
	RHfiltering(OOF,Dist,Length,ratio,Xcent, Ycent);
	Newcount = roiManager("count");
	selectWindow("TopHat-1");
	
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
		selectWindow("TopHat-1");
		run("Select All");
		roiManager("select", n+2);
		run("Duplicate...", " ");
		run("Analyze Skeleton (2D/3D)", "prune=[shortest branch] calculate show exclude calculate");
		Branch[n]= "No";
	    Length[n] = getResult("Longest Shortest Path", 0);
	    if (getResult("# Branches", 0)>1) {
	    Branch[n]= "Yes";	
	    }
	print(f,title+"\t"+(n+1)+"\t"+Dist[n]+"\t"+Length[n]+"\t"+OOF[n]+"\t"+Branch[n]+"\t"+Xcent[n]+"\t"+Ycent[n]);
	run("Clear Results");
	close("Branch information");
	close("Longest shortest paths");
	close("Tagged skeleton");
	close("TopHat-2");
	    }
	    roiManager("select", Filtarray);
		roiManager("Combine");
		roiManager("add");
		roiManager("select", roiManager("count")-1);
		roiManager("rename", "Selected_Root_Hairs");
	    }
	    else {
	print(f,title+"\t No Root hairs\t ND \t ND \t ND \t ND \t ND \t ND");    	
	    }
	selectWindow(title);
	close("\\Others");
	roiManager("Deselect");
	setBatchMode(false);
	}
	
function RHfiltering(OOF,Dist,Length,ratio,Xcent,Ycent) {
	run("Clear Results");
	roiManager("select", 0); 
	run("Measure");
	MeanRoot= getResult("Mean", 0);	
	count = roiManager("count");	
	run("Clear Results");
	for (m = 0; m < count-2; m++) {
	roiManager("select", m+2);
//	run("Enlarge...", "enlarge=-1 pixel");
	run("Measure");
	MeanRH= getResult("Mean", m);
	Xcent[m]= getResult("XM", m);
	Ycent[m]= getResult("YM", m);
	Dist[m]=sqrt(pow((tipX-Xcent[m]),2)+pow((tipY-Ycent[m]),2));
	if (ratio<MeanRoot/MeanRH) {
		OOF[m]="Out of Focus";
	}
	else {
		OOF[m]="In Focus";
		roiManager("add");
	}
	print("RH "+m+1+" "+OOF[m]);
	print("Mean "+MeanRH+" "+MeanRoot+" "+ MeanRoot/MeanRH);
	}
		}
	
function ErodeDilate(n){
	for (p = 0; p < n; p++) {
		run("Erode");
		run("Dilate");
	}
}
