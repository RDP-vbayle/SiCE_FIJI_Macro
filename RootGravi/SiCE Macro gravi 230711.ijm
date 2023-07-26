//// FIJI macro for gravitropism essay measurements. by  Vincent Bayle 
///INPUT Timelapses of Arabidopsis seedlings
 

roiManager("Reset");
run("Clear Results");
roiManager("reset");
run("Remove Overlay");
setOption("ExpandableArrays", true);
run("Options...", "iterations=1 count=1 black do=Nothing");
Size= 500;
run("Set Measurements...", "area mean standard min center bounding fit shape integrated skewness display redirect=None decimal=5");

///get scale:
getPixelSize (unit, pixelWidth, pixelHeight);
///remove scale
run("Set Scale...", "distance=0 known=0 pixel=1 unit=pixel");

//// Input parameters

	Dialog.create("SiCE MacroGravi");
	Dialog.addMessage("		Cell segmentation parameters: \n ");
	Dialog.addNumber("Min DoG sigma",2, 1,2, "	");
	Dialog.addNumber("Max DoG sigma",4, 1,2, "	");
	Dialog.addNumber("Rolling ball size",5, 1,2, " ");
	Dialog.addNumber("Dist for T0",10, 0,2, "pixel(s)");
	Dialog.addNumber("Dist for angle measures",10, 0,2, "pixel(s)");
	
	Dialog.show();
	Min = Dialog.getNumber();
	Max = Dialog.getNumber();
	bck = Dialog.getNumber();
	DistT0 = Dialog.getNumber();
	DistTk=  Dialog.getNumber();
	

title= getTitle();
path=File.getParent(getInfo("image.directory"));
getDimensions(width, height, channels, slices, frames);

/// Result table
	title1 = "[Result summary:]"; 
	f=title1; 
	run("New... ", "name="+title1+"type=Table");
	print(f,"\\Headings: Image name \t Root nb \t First point X \t First Point Y \t Last point X \t Last Point Y \t Time \t T point X \t T Point Y \t  TO Angle \t  Angle from T0 \t  Current root Angle \t  root growth in "+unit);

/// Normalisation
	run("8-bit");
	run("Enhance Contrast...", "saturated=2 normalize process_all");


/// background removal
			run("Subtract Background...", "rolling="+bck+" stack");

///realign						
	run("StackReg ", "transformation=[Rigid Body]");
	
//setBatchMode(true);
	
///Root segmentation

				
	/// Differencial of Gaussians
			run("Duplicate...", "duplicate");
			rename("smallsigma");
			run("Duplicate...", "duplicate");
			rename("highsigma");
			selectWindow("smallsigma");
			run("Gaussian Blur...", "sigma="+Min+" stack");
			selectWindow("highsigma");
			run("Gaussian Blur...", "sigma="+Max+" stack");
			imageCalculator("Subtract create stack", "smallsigma","highsigma");
			selectWindow("Result of smallsigma");

	/// Tresholding

		setAutoThreshold("Li dark stack");
		run("Convert to Mask", "method=Li background=Dark black");
		run("Dilate", "stack");
		run("Dilate", "stack");
		run("Erode", "stack");	
		run("Erode", "stack");	
	
			rename("segmented");
			close("smallsigma");
			close("highsigma");
			close("Result of smallsigma");
			close("Result of Result of smallsigma");
	
		run("Clear Results");
		roiManager("reset");	

		selectWindow(title);
		setSlice(1);
		run("Duplicate...", " ");
		titlebis= getTitle();
		
		selectWindow("segmented");
		setSlice(1);
		run("Duplicate...", " ");
		run("Analyze Particles...", "size="+Size+"-Infinity circularity=0.00-0.4 show=Nothing display clear summarize add");
		close("segmented-1");		
			/// 
	Ycrop=Autocrop(nResults); 
	selectWindow("segmented");
	makeRectangle(0, 0, width, Ycrop+10);
setBatchMode("exit and display");
	waitForUser("Crop aerial part");
	run("Clear", "stack");
	run("Select None");	
		setSlice(1);
		roiManager("reset");	
		run("Analyze Particles...", "size="+Size+"-Infinity circularity=0.00-0.4 show=Nothing display clear summarize add");
		
	/// T0 nb of roots check

		setBatchMode("exit and display");
		selectWindow(titlebis);
		roiManager("Show All");
		waitForUser("check root number");
		selectWindow("segmented");
	
count = roiManager("count");

array = newArray(count);
  for (j=0; j<array.length; j++) {
      array[j] = j;
  }

		roiManager("select", array);	
		roiManager("Combine");
		run("Enlarge...", "enlarge=-1");
		run("Fill", "stack");
		selectWindow("ROI Manager");
		run("Clear Results");
		roiManager("deselect");
		roiManager("Measure");
		nbseedlings = roiManager("count");	

	MinS=MinSize(nResults)*0.7;
	
 setForegroundColor(255, 255, 255);
  
for (n = 2; n < slices+1; n++) {
	setSlice(n-1);
		roiManager("reset");
		run("Analyze Particles...", "size="+Size+"-Infinity circularity=0.00-0.4 show=Nothing display clear summarize add");		
	
		roiManager("select", array);	
		roiManager("Combine");
		setSlice(n);
		run("Clear", "slice");
		run("Fill", "slice");
		run("Select None");		 
}
		
	/// Tlast nb of roots check
	
		roiManager("reset");	
		setSlice(slices);
		run("Analyze Particles...", "size="+Size+"-Infinity circularity=0.00-0.4 show=Nothing display clear summarize add");
		waitForUser("check root number");		
		roiManager("select", array);	
		roiManager("Combine");
		run("Clear Outside", "stack");
		
	setSlice(1);	
	roiManager("reset");	
	run("Analyze Particles...", "size="+Size+"-Infinity circularity=0.00-0.4 show=Nothing display clear summarize add");
		
	
setBatchMode(true);
										

/// i= time point, T0: i=1
for (i = 1; i < slices+1; i++) {

// Check for oversegmentation for further timepoints		
		if (i>1) {
		run("Clear Results");
		roiManager("reset");	
		selectWindow(title);
		setSlice(i);
		run("Duplicate...", " ");
		titlebis= getTitle();
		
		selectWindow("segmented");
		setSlice(i);
		run("Analyze Particles...", "size="+MinS+"-Infinity circularity=0.00-0.4 show=Nothing display clear summarize add");		
			
		selectWindow(titlebis);
		roiManager("Show All");
		selectWindow("ROI Manager");
		NewROIsNb = roiManager("count");
		if (NewROIsNb != 	nbseedlings){
			setBatchMode(false);
			setBatchMode("exit and display");
			selectWindow(titlebis);
			roiManager("Show All");
			selectWindow("ROI Manager");
			waitForUser(" Remove extra-ROIS");	
		}
		}			
		close(titlebis);				
		run("Select None");
		newImage("Trace", "8-bit black", width, height, 1);
		roiManager("Show All");
		roiManager("Fill");
		roiManager("reset");
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
		Rootnb = getValue("results.count");

// Check for oversegmentation afterskeleton	
		if (Rootnb != 	nbseedlings){
setBatchMode(false);
		setBatchMode("exit and display");
			selectWindow("Trace");
		waitForUser("Delete wrong ROIs");
		run("Select None");
		run("Analyze Skeleton (2D/3D)", "prune=[shortest branch] calculate show exclude calculate");	
setBatchMode(true);
	}
		selectWindow("Trace");
		selectWindow("Results");
		run("Close"); 
		IJ.renameResults("Branch information","Results");

///		Arrays creation to store root tips coordinates
	if (i==1){
		firstX = newArray(Rootnb); // root tip at T0
		firstY = newArray(Rootnb); // root tip at T0
		initangle = newArray(Rootnb); //angle of root at T0
		angleDistX = newArray(Rootnb); // distal point to measure angle at time "i"
		angleDistY = newArray(Rootnb); // distal point to measure angle at time "i"
		timeX = newArray(); // root tip at Ti
		timeY = newArray();	// root tip at Ti	
	}

/// timeindex is a variable to retrieve ROI of a certain root tip according to time in TimeX and TimeY arrays
	
	timeIndex= Rootnb*(i-1);
setBatchMode(true);	

/// Retrieve X and Y root tip coordinates from Skeletonize Result table
	 for (p=0; p<Rootnb; p++){
			n=0;
		do {
				ID=false;
			SkID=getResult("Skeleton ID",p+n);
		if (SkID== p+1) {
					if(getResult("V1 y",(p+n))<100 || getResult("V2 y",(p+n))>getResult("V1 y",(p+n))){
						timeX[p+timeIndex]= getResult("V2 x",(p+n));
						timeY[p+timeIndex]= getResult("V2 y",(p+n));
						}
					else {
						timeX[p+timeIndex]= getResult("V1 x",(p+n));
						timeY[p+timeIndex]= getResult("V1 y",(p+n));	
						}
					ID=true;
					selectWindow("Trace");
					makePoint(timeX[p+timeIndex], timeY[p+timeIndex], "tiny red dot");
					run("Draw", "slice");
					roiManager("Add");
					roiManager("select", p);
					roiManager("Rename", "Root tip nb_"+(p+1)+"_T0");
				}		
			else {
					n=n+1;	
		  		}	  	
		} while (ID==false);
				 }
				 
				if (i==1)   {
				for (k = 0; k < Rootnb; k++) {
						run("Clear Results");
						doWand(timeX[k], timeY[k]);
						roiManager("add");
						roiManager("select", (Rootnb+k));
						roiManager("Rename", "Root nb_"+(k)+"_T0");
						makeOval(timeX[k]-DistT0, timeY[k]-DistT0, 2*DistT0, 2*DistT0);
						run("Make Band...", "band=1");
						roiManager("Add");
						roiManager("select",newArray((Rootnb+k),(Rootnb+k+1)));
						roiManager("AND");
						run("Measure");
						firstX[k]= getResult("XM", 0);
						firstY[k]= getResult("YM", 0);
						roiManager("Deselect");
						roiManager("select", (Rootnb+k+1));
						roiManager("Delete");
						}					
						}

				 if (i>1)   {
				for (k = 0; k < Rootnb; k++) {
						run("Clear Results");
						doWand(timeX[k+timeIndex], timeY[k+timeIndex]);
						roiManager("add");
						roiManager("select", (Rootnb+k));
						roiManager("Rename", "Root nb_"+(k)+"_T"+i);
						makeOval(timeX[k+timeIndex]-DistTk, timeY[k+timeIndex]-DistTk, 2*DistTk, 2*DistTk);
						run("Make Band...", "band=1");
						roiManager("Add");
						roiManager("select",newArray((Rootnb+k),(Rootnb+k+1)));
						roiManager("AND");
						run("Measure");
						angleDistX[k+timeIndex]= getResult("XM", 0);
						angleDistY[k+timeIndex]= getResult("YM", 0);
						roiManager("Deselect");
						roiManager("select", (Rootnb+k+1));
						roiManager("Delete");
						}						
						}
							
				close("Trace-labeled-skeletons");
				close("Longest shortest paths");	
				close("Tagged skeleton");		
				rename("Trace_T"+i);
				for (k = 0; k < Rootnb; k++) {
				angleTk= NaN;
				
				if(i==1){
				run("Clear Results");
				makeSelection("angle",newArray(firstX[k],firstX[k],timeX[k]),newArray(firstY[k]+50,firstY[k],timeY[k]));
				Overlay.addSelection;
				run("Measure");
				initangle[k]= getResult("Angle",0);
				length=0;
				print(f,title+"\t"+(k+1)+"\t"+firstX[k]+"\t"+firstY[k]+"\t"+timeX[k]+"\t"+timeY[k]+"\t"+i+"\t NaN \t NaN \t"+initangle[k]+"\t NaN \t NaN \t"+length);
				}
				
				if (i>1) {
				run("Clear Results");
				makeSelection("angle",newArray(firstX[k],firstX[k],timeX[k+timeIndex]),newArray(firstY[k]+50,firstY[k],timeY[k+timeIndex]));
				Overlay.addSelection;
				run("Measure");
				makeSelection("angle",newArray(angleDistX[k+timeIndex],angleDistX[k+timeIndex],timeX[k+timeIndex]),newArray(angleDistY[k+timeIndex]+50,angleDistY[k+timeIndex],timeY[k+timeIndex]));		
				Overlay.addSelection;
				run("Measure");
				angle= getResult("Angle",1);
				T0angle= getResult("Angle",0);
				if (i==2){
				length=pixelWidth*sqrt(pow((timeX[k+timeIndex]-firstX[k]),2)+pow((timeY[k+timeIndex]-firstY[k]),2));
				}
				else {
				length=pixelWidth*sqrt(pow((timeX[k+timeIndex]-timeX[k+timeIndex-Rootnb]),2)+pow((timeY[k+timeIndex]-timeY[k+timeIndex-Rootnb]),2));	
				}		
				print(f,title+"\t"+(k+1)+"\t"+firstX[k]+"\t"+firstY[k]+"\t"+timeX[k]+"\t"+timeY[k]+"\t"+i+"\t"+timeX[k+timeIndex]+"\t"+timeY[k+timeIndex]+"\t"+initangle[k]+"\t"+T0angle+"\t"+angle+"\t"+length);
				}			
				}
				}	
close("Segmented");
close("Summary");
close("Results");
run("Images to Stack", "name=[Segmented Trace] title=Trace use");
run("Flatten", "stack");
selectWindow(title);
run("RGB Color");
run("Combine...", "stack1=["+title+"] stack2=[Segmented Trace] combine");
setBatchMode(false);
setBatchMode("exit and display");
selectWindow("Result summary:");
//saveAs("Text", path+ File.separator + "Resultsummary.csv");


function Autocrop(nResults) { 
		index=newArray();
	for (A = 0; A < nResults; A++) {
	index[A]= getResult("BY", A);
		}
	Array.getStatistics(index, min, max, mean, stdDev);
	return max
		}

function MinSize(nResults) { 
		index=newArray();
	for (A = 0; A < nbseedlings; A++) {
	index[A]= getResult("Area", A);
		}
	Array.getStatistics(index, min, max, mean, stdDev);
	return min				
