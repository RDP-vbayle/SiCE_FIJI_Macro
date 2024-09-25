	//ImageJ macro to calculate cytoskeleton bundling indicators
// adapted from Takumi Higaki, 29-Oct-2020
// adapted from 


//reset
setOption("BlackBackground", true);
	roiManager("Reset");
	run("Clear Results");
	run("Remove Overlay");
	setOption("ExpandableArrays", true);
	run("Set Measurements...", "area mean centroid center fit shape stack redirect=None decimal=3");
	
// variables (Fibriltool)
// scaling factor for drawing of segments
var norm_constant;

//threshold for flat regions
var thresh = 2;

//default for font size
var fsize = 15;

// number for cells
var num;

// default for numbering of cells
var numbering="yes";

//defaults for drawing
var fib="No";
var drw="No";


//default for width of lines
var lwidth = 2;

var pi = 3.14159265;

////parameters selection
	Dir1=getDirectory("image");
	Dialog.create("Fibril macro v. Xxx");
	Dialog.addMessage("ImageJ macro to calculate cytoskeleton bundling indicators \n ");
	Dialog.addMessage("adapted from Takumi Higaki, 29-Oct-2020");
	Dialog.addDirectory("Select INPUT directory", Dir1);
	Dialog.addCheckbox("Cell segmentation auto?", false);
	Dialog.addChoice("Channel for membrane?\t", newArray("1", "2"));
	Dialog.addNumber(" ROI size",200, 0,3, " pixels");
	Dialog.addMessage("Fibril tool parameters");
	Dialog.addMessage("adapted from Boudaoud et al. 2014");
	Dialog.addChoice("Channel for fibrils?\t", newArray("1", "2"));
 	Dialog.addChoice("Channel for drawing\t", newArray("1","2", "No"));
 	Dialog.addNumber("Multiply linelength by\t", 1);
 	Dialog.addChoice("Numbering ROIs?\t", newArray("yes","no"));
 	 
	Dialog.show();
	Dir1=Dialog.getString();
	seg= Dialog.getCheckbox();
	mb = Dialog.getChoice();
	RectSize = Dialog.getNumber();   //ROI diameter in pixels	
	fib = Dialog.getChoice();
  	drw = Dialog.getChoice();
  	norm_constant = Dialog.getNumber();
  	numbering = Dialog.getChoice();	 
	
	list = getFileList(Dir1);
// Result table creation
	title1 = "[Result summary:]"; 
	f=title1; 
	run("New... ", "name="+title1+" type=Table");
	print(f,"\\Headings: Image name \t Cell ID \t Skewness nb \t CV  \t Average fibril orientation \t Anisotropy");
	
	
  for (k=0; k<list.length; k++) {
			showProgress(k+1, list.length);	
			setBatchMode(true);
		if(endsWith(list[k], ".czi")||endsWith(list[k], ".tif")){
			open(Dir1+list[k]);
			name = getTitle();
			basename =substring(name, 0, lengthOf(name)-4);
			getPixelSize(unit, pixelWidth, pixelHeight);

////Cell reorientation
//Auto
		 if (seg==true) {
		RootRot (name,mb);
		RootRot (name,mb);	
		 }
//Manual
		 else {
		setBatchMode("exit and display");
		setTool("line");
		Stack.setChannel(mb);
		run("Enhance Contrast", "saturated=0.35");
		waitForUser("Draw cell axis");
		isROI=selectionType();
			if (isROI==-1) {
			close();		
			}
			else {
			run("Measure");
			angle=getResult("Angle", 0);
			run("Select None");
			run("Rotate... ", "angle="+angle+90+" grid=1 interpolation=Bilinear stack");	
		 		}
		run("Clear Results");
		setBatchMode("exit and display");
		
//// ROIs points selection
			Stack.setChannel(fib);
			setTool("multipoint");
			run("Point Tool...", "type=Dot color=Red size=Medium label counter=0");
			run("Enhance Contrast", "saturated=0.35");
			waitForUser("Select point ROIs (for each slice if needed)");
			resetMinAndMax();
			run("Measure");
			nbROI=nResults;
		xpoints=newArray(); // Array to store ROIs x coordinates
		ypoints=newArray(); // Array to store ROIs y coordinates
		zpoints=newArray(); // Array to store ROIs z coordinates
		for (p = 0; p < nbROI; p++) {
			xpoints[p]= getResult("XM", p);
			ypoints[p]= getResult("YM", p);
			zpoints[p]= getResult("Slice", p);
		}
			run("Clear Results");
			for (j = 0; j < nbROI; j++) {
			setSlice(zpoints[j]);
			Stack.setChannel(fib);
			makeRectangle(xpoints[j]-RectSize/2, ypoints[j]-RectSize/2, RectSize, RectSize);
			run("Duplicate...", "title=temp");
			rename("temp");
			
/// part from Higaki et al.	41598_2020_79136_MOESM3_ESM.ijm

		width = getWidth();
	height = getHeight();
	setBatchMode(true);
	
		label = getInfo("slice.label");
		integ1 = 0.0;
		sigNum = 0.0;
		for (y=0; y<height; y++) {
			for (x=0; x<width; x++) {
				i = getPixel(x,y);
				if (i!=0){
				sigNum = sigNum + 1;
				integ1 = integ1 + i;
				}
			}
		}
		mean = integ1/sigNum;
		integ2 = 0.0;
		for (y=0; y<height; y++) {
			for (x=0; x<width; x++) {
				i = getPixel(x,y);
				dif = i - mean;
				if (i!=0){integ2 = integ2 + pow(dif, 2);}
			}
		}
		variance = integ2/sigNum;
		stdev = sqrt(variance);
		cv = stdev/mean;
		stdev3 = pow(stdev, 3);
		integ3 = 0.0;
		for (y=0; y<height; y++) {
			for (x=0; x<width; x++) {
				i = getPixel(x,y);
				dif = i - mean;
				if (i!=0){integ3 = integ3 + pow(dif, 3);}
			}
		}
		skewInteg = integ3/stdev3;
		skewness = skewInteg/sigNum;

		
		close("Temp");

/// Fibriltool		
						selectWindow(name);
						getPixelSize(unit,pixelWidth,pixelHeight);
						scale = pixelWidth;

						id = getImageID(); 
						setSlice(zpoints[j]);
						makeRectangle(xpoints[j]-RectSize/2, ypoints[j]-RectSize/2, RectSize, RectSize);
						//properties of selection
						num++ ;
						getSelectionCoordinates(vertx, verty);
						c = polygonCentre(vertx,verty);
						c0s = c[0]*scale ;
						c1s = c[1]*scale ;
						getRawStatistics(area);
						areas = area*scale*scale;
						pr = 2;
						sortie = basename+"\t"+num;
						sortie = sortie+"\t"+xpoints[j]+"\t"+ypoints[j]+"\t"+d2s(areas,pr);
						
						//extract fibril signal
						selectImage(id);
						run("Duplicate...", "title=Temp");
						run("Select All");
						getSelectionCoordinates(vertxloc, vertyloc);
						if (fib == "1") setRGBWeights(1,0,0);
							else if (fib == "2") setRGBWeights(0,1,0); 
							else exit("Fibril color undefined");
						run("8-bit");
						
						
						//compute x-gradient in "x"
						selectWindow("Temp");
						run("Duplicate...","title=x");
						run("32-bit");
						run("Translate...", "x=-0.5 y=0 interpolation=Bicubic");
						run ("Duplicate...","title=x1");
						run("Translate...", "x=1 y=0 interpolation=None");
						imageCalculator("substract","x","x1");
						selectWindow("x1");
						close();
						
						//compute y-gradient in "y"
						selectWindow("Temp");
						run ("Duplicate...","title=y");
						run("32-bit");
						run("Translate...", "x=0 y=-0.5 interpolation=Bicubic");
						run ("Duplicate...","title=y1");
						run("Translate...", "x=0 y=1 interpolation=None");
						imageCalculator("substract","y","y1");
						selectWindow("y1");
						close();
						
						
						//compute norm of gradient in "g"
						selectWindow("x");
						run("Duplicate...","title=g");
						imageCalculator("multiply","g","x");
						selectWindow("y");
						run("Duplicate...","title=gp");
						imageCalculator("multiply","gp","y");
						imageCalculator("add","g","gp");
						selectWindow("gp");
						close();
						selectWindow("g");
						w = getWidth(); h = getHeight();
						for (y=0; y<h; y++) {
							for (x=0; x<w; x++){
								setPixel(x, y, sqrt( getPixel(x, y)));
							}
						}
						//set the effect of the gradient to 1/255 when too low ; threshold = thresh
						selectWindow("g");
						for (y=0; y<h; y++) {
							for (x=0; x<w; x++){
								if (getPixel(x,y) < thresh) 
									setPixel(x, y, 255);
							}
						}
						
						//normalize "x" and "y" to components of normal
						imageCalculator("divide","x","g");
						imageCalculator("divide","y","g");
						
						
						//compute nxx
						selectWindow("x");
						run("Duplicate...","title=nxx");
						imageCalculator("multiply","nxx","x");
						//compute nxy
						selectWindow("x");
						run("Duplicate...","title=nxy");
						imageCalculator("multiply","nxy","y");
						//compute nyy
						selectWindow("y");
						run("Duplicate...","title=nyy");
						imageCalculator("multiply","nyy","y");
						
						//closing
						selectWindow("Temp");
						close();
						selectWindow("x");
						close();
						selectWindow("y");
						close();
						selectWindow("g");
						close();
						
						//averaging nematic tensor
						selectWindow("nxx");
						makeSelection("polygon",vertxloc,vertyloc);
						getRawStatistics(area,xx);
						close();
						selectWindow("nxy");
						makeSelection("polygon",vertxloc,vertyloc);
						getRawStatistics(area,xy);
						close();
						selectWindow("nyy");
						makeSelection("polygon",vertxloc,vertyloc);
						getRawStatistics(area,yy);
						close();
						
						//eigenvalues and eigenvector of texture tensor
						m = (xx + yy) / 2;
						d = (xx - yy) / 2;
						v1 = m + sqrt(xy*xy + d*d);
						v2 = m - sqrt(xy*xy + d*d);
						//direction
						tn = - atan((v2 - xx) / xy);
						//score
						scoren = abs((v1-v2) / 2 / m);
						
						//output
						tsn=tn*180/pi;
						// nematic tensor tensor
						sortie = sortie+"\t"+d2s(tsn,pr)+"\t"+d2s(scoren,2*pr);
						
						//polygon coordinates
						np = vertx.length;
						for (q=0; q<np; q++){
						xp = vertx[q]; yp = verty[q];
						sortie = sortie+"\t"+d2s(xp,pr)+"\t"+d2s(yp,pr);
						}
						
						
						
						//
						//print output
						print(sortie);
						
						
						//
						//drawing of directions and cell contour
						setBatchMode(false);
						selectImage(id);
						run("Add Selection...", "stroke=yellow width="+lwidth);
						
						
						// drawing nematic tensor
						if ( drw != "No" ) {
						u1 = norm_constant*sqrt(area)*cos(tn)*scoren + c[0];
						v1 = - norm_constant*sqrt(area)*sin(tn)*scoren + c[1];
						u2 = - norm_constant*sqrt(area)*cos(tn)*scoren + c[0];
						v2 =  norm_constant*sqrt(area)*sin(tn)*scoren + c[1];
						if (drw == "1") stroke = "red";
							else if (drw == "2") stroke = "green"; 
							else exit("Drawing color undefined");
						makeLine(u1,v1,u2,v2);
						run("Add Selection...", "stroke="+stroke+" width"+lwidth);
						}
						
						
						//print number at center
						selectImage(id);
						if (numbering == "yes") { makeText(num,c[0],c[1]);
						run("Add Selection...", "stroke="+stroke+" font="+fsize+" fill=none");
						}
						
						//restore original selection
						makeSelection("polygon",vertx,verty);

		print(f, basename+"\t"+ j+1 +"\t"+skewness+"\t"+cv+"\t"+d2s(tsn,pr)+"\t"+ d2s(scoren,2*pr));
			}	
		roiManager("Reset");
		run("Clear Results");
		close("*");		
	}}}
	
	
function RootRot (name,mb)
{
	Stack.setChannel(mb);
	run("Duplicate...", "duplicate channels=2");
	run("Z Project...", "projection=[Sum Slices]");
	setAutoThreshold("Huang dark");
	//run("Threshold...");
	setOption("BlackBackground", true);
	run("Convert to Mask");
	run("Fill Holes");
	getDimensions(width, height, channels, slices, frames);
	doWand(width/2, height/2);
	run("Fit Rectangle");
	run("Measure");
	close();
	selectWindow(name);
	close("\\Others");
	angle= -90+abs(getResult("Angle", 0));
	run("Rotate... ", "angle="+angle+" grid=1 interpolation=Bilinear stack");
	run("Clear Results");
}	

function polygonCentre(x,y){
     n =x.length;
     area1 = 0;
     xc = 0; yc = 0;
     for (i=1; i<n; i++){
		  inc = x[i-1]*y[i] - x[i]*y[i-1];
         area1 += inc;
		  xc += (x[i-1]+x[i])*inc; 
		  yc += (y[i-1]+y[i])*inc;
     }
     inc = x[n-1]*y[0] - x[0]*y[n-1];
     area1 += inc;
     xc += (x[n-1]+x[0])*inc; 
     yc += (y[n-1]+y[0])*inc;    
     area1 *= 3;
     xc /= area1;
     yc /= area1;
     return newArray(xc,yc);
}



//distance between two points (x1,y1) et (x2,y2)
function distance(x1,y1,x2,y2) {
	return sqrt((x1-x2)*(x1-x2)+(y1-y2)*(y1-y2));
   }


function printArray(a) {
  print("");
  for (i=0; i<a.length; i++)
      print(i+": "+a[i]);
}



