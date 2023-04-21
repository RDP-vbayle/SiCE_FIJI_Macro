///////// Macro for compartment number quantification in Arabidopsis thaliana  root cells
run("Clear Results");
roiManager("reset");

	Dialog.create("SICE Spot detector Plugin");
	Dialog.addMessage("This macro quantifies intracellular compartments within Arabidopsis root tissue area\n Normal mode will help you determine appropriate parameters and method for batch mode ");
	Dialog.addCheckbox("Batch mode?", true);
	Dialog.addCheckbox("Scaled images?", true);
	Dialog.addCheckbox("Automatic ROI?", true);
	Dialog.addCheckbox("particle size?", true);
	Dialog.addCheckbox("Cell type selection?", false);
	Dialog.show();
	yoff=Dialog.getCheckbox();
	scal=Dialog.getCheckbox();
	roi=Dialog.getCheckbox();
	partS=Dialog.getCheckbox();
	stg=Dialog.getCheckbox();
	
		if (scal==false)
		{
			pix= "pixel"; 
		}
		else
		{
 			pix= "µm" ;

		}
	
	run("Options...", "iterations=1 count=1 black");
	
	if (yoff==false)
		{
	ComptagepointFina() ;
		}
	else
		{
 	ComptagepointBatch() ;

}

function ComptagepointFina() {

	getDimensions(width, height, channels, slices, frames);
	if (slices>1){
		waitForUser("Select slice of interest");
		run("Duplicate...", " ");
	}
	
	run("Set Measurements...", "area display redirect=None decimal=5");
	run("Clear Results");
	roiManager("reset");
	title=getTitle();
	name = substring(title, 0, indexOf(title, "."));
	
	if (partS==true)
			{
			title3 = "Result summary:"; 
			title4 = "["+title3+"]"; 
			f=title4; 
			run("New... ", "name="+title4+" type=Table");
			print(f,"\\Headings:Picture Name\tCell area\tSpots number\tSpot Density\tMean Spot size\t Max spot Size\t Min spot size\tMinSize\tMaxSize\tcircMin\tcircMax\tSigma\tLowsigma\tFiltering Method\tTreshold"); 
			}
			else
	       { 
			title1 = "Result summary:"; 
			title2 = "["+title1+"]"; 
			f=title2; 
			run("New... ", "name="+title2+" type=Table");
			print(f,"\\Headings:Picture Name\tCell area\tSpots number\tMinSize\tMaxSize\tcircMin\tcircMax\tSigma\tLowsigma\tFiltering Method\tTreshold"); 
		
			}

	run ("8-bit");
	
	/// Dialog box for parameters + happy-unhappy loop
	
	param = newArray(9);
	param[0]=0.5;
	param[1]=99;
	param[2] =3;
	param[3] =1;
	param[4] =0.5;
	param[5] =1;
	param[8] = pix;
	
	do 
	{
	run("Clear Results");
	if (roi==true)
			{
			roiManager("reset");
			}
	param = parameters(param); 
	minSize =param[0];
	maxSize =param[1];
	sigma =param[2];
	lowsigma =param[3];
	circMin =param[4];
	circMax =param[5];
	Method =param[6];
	Filtertype =param[7];
	pix =param[8];
	
	
	if (roi==true)
			{
			
		setBatchMode(true);
		
		///// Find max pixel intensity
		
		selectWindow(title);
		run("Find Maxima...", "noise=10 output=[Point Selection]");
		run("Measure");
		Xmax= getResult("X", 0);
		Ymax= getResult("Y", 0);
		if (scal==true)
				{
			toUnscaled (Xmax, Ymax);
			}
		
			//use wavelet to determine Cell area transform it in ROI for further analyses
			
			run("Clear Results");
			selectWindow(title);	
			run("Duplicate...", "title=*");
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
		
			doWand(Xmax,Ymax);
			run("Fill");
			roiManager("Add");
		}
			else
			{
	//// Manual ROI
				run("Clear Results");
				selectWindow(title);	
				run("Select All");
				run("Duplicate...", "title=*");
				run("Duplicate...", "title=Wave");
	 			Dialog.create("ROI selection");
	 			Dialog.addCheckbox("Define new ROI?", true);
				Dialog.show();
				newROI=Dialog.getCheckbox();
	 			if (newROI==false)
				{
				roiManager("Select", 0);
				}
				else
				{
				roiManager("reset");
				setTool("polygon");
	 			do {
				waitForUser("Draw ROI");
				IsROI=selectionType();	
				} while (IsROI ==-1);
	 			roiManager("Add");
	 			}
	 				
			}	
			
		run("Measure");
		CellArea= getResult("Area",0);
			
	// selection of filtering method
		
	if (Method=="Dog")
		{		
		diffgaus(sigma,lowsigma,Filtertype);
		}
	
	if (Method=="Laplacian")
		{
			Laplac(sigma, Filtertype, title);
		}	
	
	Anapart(minSize, maxSize, circMin , circMax, Method, title, Filtertype, roi, partS);
		
	selectWindow(title);
	roiManager("select", 0);
	run("Measure");
	selectWindow("Summary");
	lines = split(getInfo(), "\n");
	headings = split(lines[0], "\t");
	values = split(lines[1], "\t");
	nbROI= parseInt(values[1]);
	selectWindow("Summary");
	run("Close");
	
	if (partS==true)
			{
			run("Clear Results");
			spotdensity =parseInt(values[1])/CellArea;
			roiManager("Show None");
			roiManager("Deselect");
			roiManager("Measure");
			selectWindow("Results");
			
			Sizes = newArray(nbROI);
			for(l=0; l<=nbROI-1; l++)
				{
			Sizes[l] = getResult("Area",l+1);
			roiManager("select", 1);
			roiManager("Delete");
			}
			Array.getStatistics(Sizes, min, max, mean, stdDev);
			print(f, title+"\t"+ CellArea +"\t"+values[1]+"\t"+ spotdensity+"\t"+mean+"\t"+max+"\t"+min+"\t"+minSize+"\t"+maxSize+"\t"+circMin+"\t"+circMax+"\t"+sigma+"\t"+lowsigma+"\t"+Method+"\t"+Filtertype);	
			}
			else
			{
			print(f, name+"\t"+ CellArea +"\t"+values[1]+"\t"+minSize+"\t"+maxSize+"\t"+circMin+"\t"+circMax+"\t"+sigma+"\t"+lowsigma+"\t"+Method+"\t"+Filtertype);
			}
			
	Dialog.create("Happyness factor");
	Dialog.addCheckbox("Unhappy?", true);
	Dialog.addCheckbox("Automatic ROI?", roi);
	Dialog.show();
	yoff=Dialog.getCheckbox();
	roi=Dialog.getCheckbox();
	} while (yoff==true);
	
	
	selectWindow("Result summary:");
	//END
		}

function ComptagepointBatch() {

	dir1 = getDirectory("Choose Source Directory ");
	dir2 = getDirectory("Choose Destination Directory ");
	list = getFileList(dir1);
	title1 = "Result summary:"; 
	title2 = "["+title1+"]"; 
	f=title2; 
	run("New... ", "name="+title2+" type=Table");
	print(f,"\\Headings:Photo\tCell type\tCell area\tSpots number\tMinSize\tMaxSize\tcircMin\tcircMax\tSigma\tFiltering Method\tTreshold");

	if (partS==true)
			{
	title1 = "Result summary:"; 
	title2 = "["+title1+"]"; 
	f=title2; 
	run("New... ", "name="+title2+" type=Table");
	print(f,"\\Headings:Picture Name\tCell type\tCell area\tSpots number\tSpot Density\tMean Spot size\t Max spot Size\t Min spot size\tMinSize\tMaxSize\tcircMin\tcircMax\tSigma\tFiltering Method\tTreshold"); 
	title3 = "Result summary particles size:"; 
	title4 = "["+title3+"]"; 
	g=title4; 
	run("New... ", "name="+title4+" type=Table");
	print(g,"\\Headings:Picture Name\tCell type\tSpots size");
			}
		else
		{
	title1 = "Result summary:"; 
	title2 = "["+title1+"]"; 
	f=title2; 
	run("New... ", "name="+title2+" type=Table");
	print(f,"\\Headings:Photo\tCell type\tCell area\tSpots number\tMinSize\tMaxSize\tcircMin\tcircMax\tSigma\tFiltering Method\tTreshold");
		}
	/// parameters dialog box 
	
	param=newArray(9);
	param[0]=0.5;
	param[1]=99;
	param[2] =3;
	param[3] =1;
	param[4] =0.5;
	param[5] =1;
	param[8] = pix;
	
	param = parameters(param); 
	minSize =param[0];
	maxSize =param[1];
	sigma =param[2];
	lowsigma =param[3];
	circMin =param[4];
	circMax =param[5];
	Method =param[6];
	Filtertype =param[7];
	
	for (i=0; i<list.length; i++) {
	    showProgress(i+1, list.length);
	    
	if (endsWith(list[i], ".TIF")==true){
	    open(dir1+list[i]);
		
	Dialog.create("Image quantifiable?");
	Dialog.addCheckbox("OK?", true);
	Dialog.show();
	Xoff=Dialog.getCheckbox();
	if (Xoff==false)
		{
	run("Close All");
		}
	else
		{

	getDimensions(width, height, channels, slices, frames);
	if (slices>1){
		waitForUser("Select slice of interest");
		run("Duplicate...", " ");
		}
	
	/// Stage
	
	if (stg==true){	
		Dialog.create("Cell type selection:");
		Dialog.addChoice(" ", newArray("Meristem","Elongation","Mature unknown","Mature Thricho.", "Mature Athricho."));
		Dialog.show();				
		stage = Dialog.getChoice();
		}
	else {
		stage = "ND";
	}
			
	///////// Macro for compartment number quantification in Arabidopsis thaliana  root cells
	
	run("Set Measurements...", "area display redirect=None decimal=5");
	run("Clear Results");
	roiManager("reset");
	title=getTitle();
    name = substring(title, 0, indexOf(title, "."));
	
	if (roi==true)
			{
	
	setBatchMode(true);
		
		///// find maximum intensity pixel
		
		selectWindow(title);
		run("Find Maxima...", "noise=10 output=[Point Selection]");
		run("Measure");
		Xmax= getResult("X", 0);
		Ymax= getResult("Y", 0);
		if (scal==true)
			{
		toUnscaled (Xmax, Ymax);
		}
			//use wavelet to determine Cell area transform it in ROI for further analyses
			
			run("Clear Results");
			selectWindow(title);	
			run("Duplicate...", "title=*");
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
		
			doWand(Xmax,Ymax);
			run("Fill");
			}
			else
			{
	//// Manual ROI
				setBatchMode(false);
				run("Clear Results");
				selectWindow(title);	
				run("Select All");
				run("Duplicate...", "title=*");
				run("Duplicate...", "title=Wave");
				setTool("polygon");
	 			do {
				waitForUser("Draw ROI");
				IsROI=selectionType();	
				} while (IsROI ==-1);
	 			}
	 				
				
		run("Measure");
		CellArea= getResult("Area",0);
		roiManager("Add");

	
	// selection of filtering method
		
	
	if (Method=="Dog")
		{	
		diffgaus(sigma,lowsigma,Filtertype);
		}
	
	if (Method=="Laplacian")
		{
			Laplac(sigma, Filtertype, title);
		}	
	
	Anapart(minSize, maxSize, circMin, circMax, Method, title, Filtertype, roi, partS);
	saveAs("Tiff", dir2+name+" analysed");	
	selectWindow("Summary");
	lines = split(getInfo(), "\n");
	headings = split(lines[0], "\t");
	values = split(lines[1], "\t");
	nbROI= parseInt(values[1]);
	selectWindow("Summary");
	run("Close");
	
	if (partS==true)
			{
			run("Clear Results");
			spotdensity =parseInt(values[1])/CellArea;
			roiManager("Show None");
			roiManager("Deselect");
			roiManager("Measure");
			selectWindow("Results");
			
			Sizes = newArray(nbROI);
			
			
			for(l=0; l<=nbROI-1; l++)
				{
			Sizes[l] = getResult("Area",l+1);
			roiManager("select", 1);
			roiManager("Delete");
			print(g, title+"\t"+ Sizes[l]);
			}
			Array.getStatistics(Sizes, min, max, mean, stdDev);
			print(f, title+"\t"+ stage +"\t"+ CellArea +"\t"+values[1]+"\t"+ spotdensity+"\t"+mean+"\t"+max+"\t"+min+"\t"+minSize+"\t"+maxSize+"\t"+circMin+"\t"+circMax+"\t"+sigma+"\t"+lowsigma+"\t"+Method+"\t"+Filtertype);
			
			}
			else
			{
			print(f, name+"\t"+ stage +"\t"+ CellArea +"\t"+values[1]+"\t"+minSize+"\t"+maxSize+"\t"+circMin+"\t"+circMax+"\t"+sigma+"\t"+lowsigma+"\t"+Method+"\t"+Filtertype);
			}
	}
	if (Xoff==true)
		{
		if (roi==false)
			{
	Dialog.create("Another ROI?");
	Dialog.addCheckbox("OK?", true);
	Dialog.show();
	yoff=Dialog.getCheckbox();
	if (yoff==true)
		{
	i=i-1;
		}
		else
			{
			run("Close All");
			}
		}
		}
	}
	}
	run("Close All");
	close("Log");
	selectWindow("Result summary:");
	}
	
function parameters(param) {
	Dialog.create("Select Parameters");
	Dialog.addNumber("Min Particle Size ("+param[8]+"^2)",param[0], 3,6,"");
	Dialog.addNumber("Max Particle Size ("+param[8]+"^2)",param[1], 3,6,"");
	Dialog.addNumber("UpperSigma",param[2], 1,3, "Radius");
	Dialog.addNumber("LowerSigma",param[3], 1,3, "Radius");
	Dialog.addNumber("Circularity Min",param[4], 1,3, "");
	Dialog.addNumber("Circularity Max",param[5], 1,3, "");
	Dialog.addChoice("Filtering method", newArray("DoG", "Laplacian"));
	Dialog.addChoice("Auto-threshold", newArray("Triangle", "Otsu", "Huang"));
	Dialog.show();
	minSize = Dialog.getNumber();
	maxSize = Dialog.getNumber();
	sigma = Dialog.getNumber();
	lowsigma = Dialog.getNumber();
	circMin = Dialog.getNumber();
	circMax = Dialog.getNumber();
	Method = Dialog.getChoice();
	Filter = Dialog.getChoice();

	param = newArray(minSize, maxSize, sigma,lowsigma, circMin, circMax, Method, Filter, pix);
	return param;
	
}


function diffgaus(sigma,lowsigma,Filtertype) {
		selectWindow("*");
		run("8-bit");
		run("Subtract Background...", "rolling=5");
		run("Duplicate...", "title=DoG-3");
		run("Duplicate...", "title=DoG-1");
		selectWindow("DoG-3");
		run("Gaussian Blur...", "sigma="+sigma+"");
		selectWindow("DoG-1");
		run("Gaussian Blur...", "sigma="+lowsigma+"");
		rename("DoG-1");
		imageCalculator("Subtract create", "DoG-1","DoG-3");
		rename("DoG");
		close("DoG-1");
		close("DoG-3");
		selectWindow("DoG");
		roiManager("select", 0);
 	   	run("Clear Outside");
	
	///autothresholding
	
		if (Filtertype=="Otsu")
			setAutoThreshold("Otsu dark");
		if (Filtertype=="Triangle")
		setAutoThreshold("Triangle dark");
		if (Filtertype=="Huang")
		setAutoThreshold("Huang dark");
   		run("Convert to Mask");
		rename("titlebis");
}

function Laplac(sigma, Filtertype, title) {
		selectWindow("*");
		run("8-bit");
		run("Subtract Background...", "rolling=5");
		
		run("FeatureJ Laplacian", "compute smoothing="+sigma+"");
		roiManager("select", 0);
		run("Clear Outside");
		
	///autothresholding
	
		if (Filtertype=="Otsu")
			setAutoThreshold("Otsu");
		if (Filtertype=="Triangle")
		setAutoThreshold("Triangle");
		if (Filtertype=="Huang")
		setAutoThreshold("Huang");	
		run("Convert to Mask");
		rename("titlebis");
		}

function Anapart(minSize, maxSize, circMin, circMax, Method, title, Filtertype, roi, partS) {
	
		if (partS==true)
			{
		run("Analyze Particles...", "size="+minSize+"-"+maxSize+"  circularity= "+ circMin +"-"+ circMax +" show=[Bare Outlines] exclude summarize add in_situ");
			}
		else
			{
		run("Analyze Particles...", "size="+minSize+"-"+maxSize+"  circularity= "+ circMin +"-"+ circMax +" show=Ellipses display exclude summarize in_situ");
		}
		rename("done");
		run("Merge Channels...","c4=done c2=*");
		setBatchMode(false);
		selectWindow("RGB");
		rename(title+ Method+ " counted spots S"+sigma+ " - "+lowsigma+ " F "+ Filtertype);
		close("wave");
			if (roi==true)
			{
		close("coeff-2");
		close("plan");
		}
		}
