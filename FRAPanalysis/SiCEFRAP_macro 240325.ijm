///// SiCE FRAP analysismacro. The macro will identify the beached ROIs and record fluorescence intensity from control and bleached regions.
// INPUT: .stk or .nd files corresponding to FRAP time lapse acquisisions

	setOption("BlackBackground", true);
	roiManager("Reset");
	run("Clear Results");
	run("Remove Overlay");
	setOption("ExpandableArrays", true);
	run("Set Measurements...", "area mean centroid center fit shape stack redirect=None decimal=3");

////parameters selection

	Dialog.create("SiCE FRAP analysis Plugin");
	Dialog.addMessage("This macro quantifies FRAP within Arabidopsis root tissue \n ");
	Dialog.addNumber("FRAP zone lenght",60, 0,3, "pixels");
	Dialog.addNumber("Membrane thickness",10, 0,3, "pixels");
	Dialog.addChoice("Orientation of bleaching", newArray("cortical","Lateral Membrane", "Apico basal Membrane"));
	Dialog.addNumber(" prebleach image number",12, 0,3, " Frame");
	Dialog.addNumber(" Find max proheminence",1000, 0,3, " ");
	Dialog.addNumber(" ROIs nb",3, 0,3, " ");
	Dialog.show();
	zone = Dialog.getNumber();
	mbt = Dialog.getNumber();
	ori = Dialog.getChoice();
	preB = Dialog.getNumber();
	MaxX = Dialog.getNumber();
	ROIs = Dialog.getNumber();

	dir1 = getDirectory("Choose Input Directory ");
	list1 = getFileList(dir1);
	
	if (ori=="cortical"){
		minZone=pow(zone/2, 2)*PI*3/4;
		maxZone=3*minZone;
	}
	else {
		minZone=3*zone;
		maxZone=50*zone;
	}

				for (m=0; m<list1.length; m++) {					
				showProgress(m+1, list1.length);
		if (endsWith(list1[m], ".nd")||endsWith(list1[m], ".stk")) {
		run("Bio-Formats (Windowless)", "open=["+dir1+list1[m]+"]");

//background removal	
		//getPixelSize (unit, pixelWidth, pixelHeight);		
		run("Set Scale...", "distance=0 known=1 unit=micron");
		setTool("point");
		run("Z Project...", "projection=[Sum Slices]");
		Dialog.create(" ");
		Dialog.addCheckbox("XY Drift?", true);
		Dialog.show();
		stag = Dialog.getCheckbox();
		close();
// XY drift correction using Fast4Reg plugin
		if (stag ==true){
	setBatchMode(true);
		run("F4DR Estimate Drift", "time=10 max=0 reference=[previous frame (better for live)] apply choose=["+dir1+"]");				
		File.delete(dir1+"DriftTable.njt");
	setBatchMode(false);
		  }
		  
// Noise substraction
		waitForUser("Select Noisy Area (Select none to skip background subtraction");
		select = selectionType(); 
		if (select!=-1)
						{
	setBatchMode(true);
		run("Measure");
		Xbck= getResult("X", 0);
		Ybck= getResult("Y", 0);
		makeOval((Xbck-15), (Ybck-15), 30, 30);
		run("Measure");
		background = getResult("Mean",1);
		run("Select None");
		run("Subtract...", "value="+background+" stack");
		}
		
		Stack.getDimensions(width, height, channels, slices, frames);
		title=getTitle();
		
		run("Clear Results");
		roiManager("reset");	
		makeRectangle((width/4), (height/4), (width/2), (height/2));
		run("Find Maxima...", "noise="+MaxX+" exclude output=[Point Selection]");
		run("Measure");
		Xmax= getResult("Y", 0);
		Ymax= getResult("Y", 0);
		//toUnscaled (Xmax, Ymax);
		run("Select All");
		
// Root segmentation using wavelet
		
	if (ori!="cortical"){	
			run("Clear Results");
			run("Duplicate...", "title=Wave");
			run("Select All");
			roiManager("Add");
			run("Wavelet A Trou");
			run("Stack to Images");
			close("coeff-5");
			close("coeff-4");
			close("coeff-2");
			close("coeff-3");
			close("coeff-1");
			roiManager("reset");
			selectWindow("plan");
			setAutoThreshold("Otsu dark");
			run("Convert to Mask");
			run("Fill Holes");
			run("Select None");
			setTool("wand");
			doWand(Xmax,Ymax);
			select = selectionType(); 
			if (select==-1)
						{
						waitForUser("");
						}
			
//determine root orientation 
			
			run("Measure");
			run("Fit Ellipse");
			angle= getResult("Angle",0);
			close("plan");
			close("wave");
						
//stack rotation 

			selectWindow(title);
			run("Rotate... ", "angle="+angle+" grid=1 interpolation=Bilinear stack");
			roiManager("reset");
			}
			
// bleached ROIs identification
	
		selectWindow(title);
		run("Duplicate...", "duplicate range=1-1");
		rename("1");
		run("Gaussian Blur...", "sigma=2");
		selectWindow(title);
		run("Duplicate...", "duplicate range=	"+preB+"-"+preB+"");
		rename("Bleached");
		run("Gaussian Blur...", "sigma=2");
		imageCalculator("Subtract create", "1","Bleached");
		selectWindow("Result of 1");
		run("Set Measurements...", "centroid fit redirect=None decimal=5");
		setAutoThreshold("Default dark");
		XROI = newArray;
		YROI = newArray;
		Ang	= newArray;	
		setOption("BlackBackground", true);
		run("Convert to Mask");
		selectWindow("Result of 1");
		run("Analyze Particles...", "size="+minZone+"-"+maxZone+" show=Nothing display exclude summarize add in_situ ");
		nbROI=roiManager("count");
		
		if (ROIs!=nbROI) {
setBatchMode("exit and display");
		waitForUser("Remove non bleached ROIs!");
		nbROI=roiManager("count");
		}	
		roiManager("Deselect");
		roiManager("multi-measure measure_all");
		
/// Bleached ROIs angle correction		

	if (ori!="cortical"){
		for(i=0; i<=nbROI-1; i++)
				{
		corr= getResult("Angle", i);
		
		if (-180<corr && corr<-90){
		Ang[i]=180-abs(corr);	
		}
		if (-90<corr && corr<0){
		Ang[i]=abs(corr);	
		}
		if (90<corr && corr<180){
		Ang[i]=-(180-corr);	
		}
		else {
		Ang[i]=corr;		
		}
				}	
		run("Clear Results");		
		
		Array.getStatistics(Ang, min, max, mean, std);
		selectWindow("Result of 1");
		run("Select None");
		run("Rotate... ", "angle="+mean+" grid=1 interpolation=Bilinear ");
		selectWindow(title);
		run("Rotate... ", "angle="+mean+" grid=1 interpolation=Bilinear stack");		
		roiManager("Reset");
		run("Clear Results");
		selectWindow("Result of 1");
		roiManager("show none");
		setAutoThreshold("Default dark");
		run("Convert to Mask");
		
		run("Analyze Particles...", "size="+minZone+"-"+maxZone+" show=Nothing display exclude summarize add in_situ ");
		
		roiManager("Deselect");
		roiManager("multi-measure measure_all");
		}

		for(i=0; i<=nbROI-1; i++)
				{
		XROI[i]= getResult("X", i);
		YROI[i]= getResult("Y", i);
				}	
		run("Clear Results");		

		
		run("Clear Results");	
		//close("*");
		close("1");
		close("Bleached");
		close("Result of 1");
		setBatchMode(false);
		selectWindow(title);
		roiManager("Show All");
		roiManager("Show All");
	
//Add control ROIs
		setTool("multipoint");
		resetMinAndMax();
		waitForUser("Select control ROIs (one point per bleached ROI)");
		roiManager("Show None");
		run("Measure");
		XctrlROI = newArray;
		YctrlROI = newArray;
		for(i=0; i<=nbROI-1; i++)
				{
		XctrlROI[i]= getResult("X", i);
		YctrlROI[i]= getResult("Y", i);
				}
				
		run("Clear Results");
		roiManager("reset");
		

		for(i=0; i<=nbROI-1; i++)
				{	
						if (ori=="cortical"){
		makeOval(XctrlROI[i]-(zone/2), YctrlROI[i]-(zone/2), zone, zone);
		roiManager("Add");
		makeOval(XROI[i]-(zone/2), YROI[i]-(zone/2), zone, zone);
		roiManager("Add");
			}
						else {
					makeRectangle(XctrlROI[i]-(zone/2), YctrlROI[i]-((mbt+2)/2), zone, (mbt+2));
					roiManager("Add");
					makeRectangle(XROI[i]-(zone/2), YROI[i]-((mbt+2)/2), zone, (mbt+2));
					roiManager("Add");
			}
				}
		
//Make measurements
		roiManager("Deselect");
		roiManager("Multi Measure");
		selectWindow("Summary");
		run("Close");
		waitForUser("Copy results");
		roiManager("Reset");
		run("Clear Results");
		close("Summary");
		run("Close All");
			} }

function ROIsanalysis (zone,XROI, YROI,Ang, nbROI )
{
		selectWindow("Result of 1");
		run("Analyze Particles...", "size="+(3*zone)+"-"+(30*zone)+" show=Nothing display summarize add in_situ");
		selectWindow("Summary");
			lines = split(getInfo(), "\n");
			headings = split(lines[0], "\t");
			values = split(lines[1], "\t");

		nbROI= values[1];
		
		roiManager("Deselect");
		roiManager("multi-measure measure_all");

		for(i=0; i<=nbROI-1; i++)
				{
		Ang[i]= getResult("Angle", i);
		XROI[i]= getResult("X", i);
		YROI[i]= getResult("Y", i);
				}	
		run("Clear Results");		
}
