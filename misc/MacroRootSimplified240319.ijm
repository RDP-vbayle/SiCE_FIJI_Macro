///////Macro for feature extractiono of Root tissues (mb size, angles, etc...)
///get scale:
getPixelSize (unit, pixelWidth, pixelHeight);
if (unit!="pixel"){
xPIX=pixelWidth;}
else exit ("No calib");

getDimensions(width, height, channels, slices, frames);
setOption("BlackBackground", true);
roiManager("Reset");
run("Clear Results");
roiManager("reset");
run("Remove Overlay");
setOption("ExpandableArrays", true);
run("Overlay Options...", "stroke=Red width=0 fill=Red set");
run("Roi Defaults...", "color=red stroke=0 group=0");
run("Set Measurements...", "area mean centroid center bounding fit shape stack redirect=None decimal=3");
title=getTitle();

///rotation
	run("Select All");
	run("Duplicate...", " ");
	rename("Z");
	setAutoThreshold("Huang dark no-reset");
	//run("Threshold...");
	setOption("BlackBackground", true);
	run("Convert to Mask");
	run("Fill Holes");
	run("Distance Map");
	setAutoThreshold("Huang dark no-reset");
	doWand(width/2, height/2);
	run("Measure");
	angl= -90+getResult("Angle", 0);
	close("Z");
	selectWindow(title);
	run("Rotate... ", "angle="+angl+" grid=1 interpolation=Bilinear fill stack");
	run("Set Scale...", "distance=0 known=0 pixel=1 unit=pixel");


////Parameter selection

	Dialog.create("SiCE DivMacroRoot Simplified");
	Dialog.addMessage("  \n ");
	Dialog.addCheckbox("Correct orientation?", true);
	Dialog.addCheckbox("Global Three way junctions analysis?", true);
	Dialog.addMessage("		Cell segmentation parameters: \n ");
	Dialog.addNumber("Min Cell size",100, 1,5, "pixels^2");
	Dialog.addNumber("Max Cell size",20000, 1,5, "pixels^2");
	Dialog.addNumber("Wavelet plane",2, 1,5, " 2 to 4 ");
	Dialog.addNumber("Distance Map noise",2, 1,2, " "); // sur ou sous-segmentation
	Dialog.addCheckbox("Manual cell removal?", true);
	Dialog.addMessage("		Edges detection parameters: \n ");
	Dialog.addNumber("Cell file Minimal distance",30, 1,2, "pixels");
	Dialog.addNumber("Minimal distance to measure corners",5, 1,2, "pixels");
	Dialog.show();
	ori=Dialog.getCheckbox();
	Tway=Dialog.getCheckbox();
	CellMin = Dialog.getNumber();
	CellMax = Dialog.getNumber();
	wave = Dialog.getNumber();
	Noiz = Dialog.getNumber();
	remov=--Dialog.getCheckbox();
	CFlimt=Dialog.getNumber();
	PTlimit=Dialog.getNumber();
	

if (Tway==true){
	g = "[Three way juntions summary:]";
	run("New... ", "name="+g+" type=Table");
	print(g,"\\Headings: Image name \t Junction number\t TWJ X \t TWJ Y \t Angle1 \t Angle2 \t Angle3");
	}

if (ori==false)
			{
run("Rotate... ", "angle=180 grid=1 interpolation=Bilinear fill stack");
			}

/// background removal
	run("Subtract Background...", "rolling=50 stack");

/// Plane selection
	setTool("rectangle");
	waitForUser("Select Z/ , rotate & crop if needed");
	getSelectionBounds(xCROP, yCROP, widthCROP, heightCROP);
	run("Select None");
	Zslice=getSliceNumber();
	run("Despeckle", "slice");
	run("Despeckle", "slice");
	run("Duplicate...", "duplicate range="+Zslice+"-"+Zslice+"");
	rename("cells");
setBatchMode(true);

///Cell segmentation

	//Wavelet filtering
			run("Select All");
			roiManager("Add");
			run("Wavelet A Trou");
			run("8-bit");
			selectWindow("Wavelet");
			setSlice(wave);
			run("Duplicate...", "duplicate range="+wave+"-"+wave+"");
			rename("mb");
			close("Wavelet");

	//Tresholding
			selectWindow("mb");
			setAutoThreshold("Percentile dark no-reset");
			run("Convert to Mask");
			run("Duplicate...", " ");
			run("Invert");
			run("Fill Holes");

	//Markerbased Watershed

			run("Distance Map");
			run("Find Maxima...", "noise="+Noiz+" output=[Single Points]");
			rename("mb-2");
			run("Marker-controlled Watershed", "input=cells marker=[mb-2] mask=None compactness=0 binary calculate use");
			close("mb-2");
			close("mb-1");
			close("mb");
			close("plan");
			run("8-bit");
			setThreshold(2, 255, "raw");
			run("Convert to Mask");
	// MAke the CROP

			makeRectangle(xCROP, yCROP, widthCROP, heightCROP);
			run("Crop");

	//particle analysis
			run("Analyze Particles...", "size="+CellMin+"-"+CellMax+" circularity=0.30-1.00 show=Outlines display exclude clear add");
			selectWindow("cells-watershed");
			run("Select None");
			run("Invert");
			selectWindow("cells");
			close("Drawing of cells-watershed");
			if (remov==true)
			{
			selectWindow("ROI Manager");
			// MAke the CROP
setBatchMode("exit and display");
			selectWindow("cells-watershed");
			makeRectangle(xCROP, yCROP, widthCROP, heightCROP);
			selectWindow("cells");
			makeRectangle(xCROP, yCROP, widthCROP, heightCROP);
			run("Crop");
			roiManager("Show All");
	waitForUser("Remove abnormal objects in ROImanager");
	
	Dialog.create("Cells checkpoint");
	Dialog.addMessage("Select pair of cells with correct division plane \n ");
	Dialog.addString("Cell 1","2,4, , , ");
	Dialog.addString("Cell 2","3,5, , , ");
	Dialog.addMessage("Select pair of cells with wrong division plane \n ");
	Dialog.addString("Cell 1","2,4, , , ");
	Dialog.addString("Cell 2","3,5, , , ");
	Dialog.show();
	
	strCR = Dialog.getString();
	strCL = Dialog.getString();
	strR = Dialog.getString();
	strL = Dialog.getString();
	
	idxCR = num2array(strCR,",");
	idxCL = num2array(strCL,",");
	idxR = num2array(strR,",");
	idxL = num2array(strL,",");
	
	d = "[Correct div. summary:]";
	run("New... ", "name="+d+" type=Table");
	print(d,"\\Headings: Image name \t Junction nb \t Cell 1 number \t Cell 1 File \t Cell 1 Area \t Cell 2 number \t Cell 2 File \t Cell 2 Area \t Length \t Membrane Angle");	
	
	if (idxR.length>0 ) {
	pbDiv=true;	
	h = "[Abnormal div. summary:]";
	run("New... ", "name="+h+" type=Table");
	print(h,"\\Headings: Image name \t Junction nb \t Cell 1 number \t Cell 1 File \t Cell 1 Area \t Cell 2 number \t Cell 2 File \t Cell 2 Area \t Length \t Membrane Angle");	
	}	
			}
			nROIs = roiManager("count");

setBatchMode(true);
	Xcent= newArray;
	Ycent= newArray;
	Area= newArray;
	Width= newArray;
	Xtway=newArray();
	Ytway=newArray();
	XtwayPot=newArray();
	YtwayPot=newArray();

	run("Clear Results");

////Loop cell analysis

for(l=0; l<=nROIs-1; l++)
			{
// Mesure centroid and area
				roiManager("Select", l);
				run("Measure");
				Xcent[l]=  getResult("X",l);
				Ycent[l]=  getResult("Y",l);
				Area[l]= getResult("Area", l)*(pow(xPIX,2));
				Width[l]=  getResult("Width",l);
			}
	run("Clear Results");
	run("Select All");
	run("Duplicate...", " ");
	run("Select All");
	run("Clear", "slice");

// Cell file identification
///Cell nb sorting according X centroid for the 7th first older cells 

	XcentFirst=Array.trim(Xcent,7);
	sortedXcentFirst = Array.copy(XcentFirst);
	Array.sort(sortedXcentFirst);
	rankPosArrBis = Array.rankPositions(XcentFirst);
	CF=1;
	cellFile=newArray;
	CentL=newArray;
	WidthL=newArray;
	firstelement=true;

for (cc=0; cc<6; cc++){
	cellFile[rankPosArrBis[cc]]=CF;
	centDist =sortedXcentFirst[cc+1] - sortedXcentFirst[cc];
	if (firstelement==true)
				{
	CentL[CF-1]= sortedXcentFirst[cc];
	WidthL[CF-1]= Width[rankPosArrBis[cc]];
				}
	if (centDist>=CFlimt)
				{
		CF=CF+1;
		firstelement=true;
				}
	else {
		firstelement=false;
	}
	}
	nLayer=CentL.length;

////retrieve cell file for all the cells

for(l=0; l<=nROIs-1; l++)
	{	
	for (i = 0; i < nLayer; i++) {
		centDist=abs(Xcent[l]-CentL[i]);
		if (centDist<=(WidthL[i]/2)) {
		cellFile[l]=i+1;	
		}
	}
	}
		run("Clear Results");

/// creation matrice, definition membrane apicale
			HLx = newArray;
			HRx = newArray;
			HLy = newArray;
			HRy = newArray;

// Edges identification using Skeleton

				selectWindow("cells-watershed");
				run("Convert to Mask");
				run("Dilate");
				run("Skeletonize (2D/3D)");
				selectWindow("cells-watershed");
				run("Analyze Skeleton (2D/3D)", "prune=none");
				selectWindow("Tagged skeleton");
				rename("skeleton");
				run("Duplicate...", " ");
				rename("mb");
				setThreshold(95, 255, "raw");
				run("Convert to Mask");
				selectWindow("skeleton");
				setThreshold(48, 94, "raw");
				rename("nodes");
				run("Convert to Mask");
				run("Dilate");
				run("Analyze Particles...", "size=0-20000 display clear");
				newImage("Tway", "8-bit black", widthCROP, heightCROP, 1);
				XtwayF=newArray();
				YtwayF=newArray();
				nbRWJ= nResults;
				selectWindow("Tway");
				run("Select All");
				run("Clear", "slice");

				for (i = 0; i < nbRWJ; i++) {
					XtwayF[i]=getResult("X", i);
					YtwayF[i]=getResult("Y", i);
					}

				newImage("Cell", "8-bit black", widthCROP, heightCROP, 1);

/// Tree way junction
	 	 	if (Tway==true)
			{
				selectWindow("Tway");
				run("Select All");
				run("Clear", "slice");
				for (i = 0; i < nbRWJ; i++) {
					makeOval(XtwayF[i]-PTlimit, YtwayF[i]-PTlimit, 2*PTlimit, 2*PTlimit);
					run("Draw", "slice");
					imageCalculator("AND create", "cells-watershed","Tway");
					run("Analyze Particles...", "size=0-20000 circularity=0-1.00 show=Nothing display clear");
					if (nResults==3){
					makeSelection("angle",newArray(getResult("X", 0),XtwayF[i],getResult("X", 1)),newArray(getResult("Y", 0),YtwayF[i],getResult("Y", 1)));
					run("Measure");
					makeSelection("angle",newArray(getResult("X", 0),XtwayF[i],getResult("X", 2)),newArray(getResult("Y", 0),YtwayF[i],getResult("Y", 2)));
					run("Measure");
					makeSelection("angle",newArray(getResult("X", 1),XtwayF[i],getResult("X", 2)),newArray(getResult("Y", 1),YtwayF[i],getResult("Y", 2)));
					run("Measure");
					print(g,title+"\t"+(i+1)+"\t"+XtwayF[i]+"\t"+YtwayF[i]+"\t"+getResult("Angle", 3)+"\t"+getResult("Angle", 4)+"\t"+getResult("Angle", 5));
					selectWindow("cells");
					makePoint(XtwayF[i], YtwayF[i], "medium yellow cross");
					run("Add Selection...");
					}
					selectWindow("Tway");
					run("Select All");
					run("Clear", "slice");
					close("Result of cells-watershed");
				}
				run("Clear Results");
			}
		close("Tway");
		close("nodes");
		close("mb");
		close("Cell");
		
newImage("Temp", "8-bit black", widthCROP, heightCROP, 1);

	for (i = 0; i < idxCR.length; i++) {
		run("Duplicate...", " ");
		rename("Temp-1");
		roiManager("Select", idxCL[i]-1);
		run("Enlarge...", "enlarge=2");
		run("Fill", "slice");
		selectWindow("Temp");
		run("Duplicate...", " ");
		rename("Temp-2");
		roiManager("Select", idxCR[i]-1);
		run("Enlarge...", "enlarge=2");
		run("Fill", "slice");
		imageCalculator("AND ", "Temp-1","Temp-2");
		selectImage("Temp-1");
		run("Skeletonize");
		run("Analyze Particles...", "size=0-20000 display clear");
		DivAngle=getResult("Angle", 0);
		run("Clear Results");
		run("Analyze Skeleton (2D/3D)", "prune=none show");
		IJ.renameResults("Branch information","Results");
		DivLength=getResult("Branch length", 0);
		print(d,title+"\t"+(i+1)+"\t"+idxCL[i]+"\t"+cellFile[idxCL[i]-1]+"\t"+Area[idxCL[i]-1]+"\t"+idxCR[i]+"\t"+cellFile[idxCR[i]-1]+"\t"+Area[idxCR[i]-1]+"\t"+DivLength+"\t"+DivAngle);
		close("Temp-2");
		close("Temp-1");
		close("Tagged skeleton");
	}	
	
if (pbDiv==true ) {

	for (i = 0; i < idxR.length; i++) {
		run("Duplicate...", " ");
		rename("Temp-1");
		roiManager("Select", idxL[i]-1);
		run("Enlarge...", "enlarge=2");
		run("Fill", "slice");
		selectWindow("Temp");
		run("Duplicate...", " ");
		rename("Temp-2");
		roiManager("Select", idxR[i]-1);
		run("Enlarge...", "enlarge=2");
		run("Fill", "slice");
		imageCalculator("AND ", "Temp-1","Temp-2");
		selectImage("Temp-1");
		run("Skeletonize");
		run("Analyze Particles...", "size=0-20000 display clear");
		DivAngle=getResult("Angle", 0);
		run("Clear Results");
		run("Analyze Skeleton (2D/3D)", "prune=none show");
		IJ.renameResults("Branch information","Results");
		DivLength=getResult("Branch length", 0);
		print(h,title+"\t"+(i+1)+"\t"+idxL[i]+"\t"+cellFile[idxL[i]-1]+"\t"+Area[idxL[i]-1]+"\t"+idxR[i]+"\t"+cellFile[idxR[i]-1]+"\t"+Area[idxR[i]-1]+"\t"+DivLength+"\t"+DivAngle);
		close("Temp-2");
		close("Temp-1");
		close("Tagged skeleton");
	}
}

Array.print(idxCL);
Array.print(idxCR);
Array.print(idxL);
Array.print(idxR);
Array.print(idxCL);
Array.print(Area);
Array.print(cellFile);

close("Temp");
close("cells-watershed");

function Corneridentif(Xcoin, Ycoin, X0, Y0 ){
		TLC= newArray;
	for (ii=0; ii<=Ycoin.length-1; ii++){
		TLC[ii]=sqrt( pow( (X0 - Xcoin[ii]),2) + pow( (Y0 - Ycoin[ii]),2) );
		Array.getStatistics(TLC, min, max, mean, stdDev);
		}
	for (k=0; k<TLC.length; k++){
          if (TLC[k]==min) 
         {index= k;
          }
          }
		return index;
}

function AngleCorner(xCorner, yCorner, PTlimit){
	selectWindow("Tway");
	run("Select All");
	run("Clear", "slice");
	makeOval(xCorner-2*PTlimit, yCorner-2*PTlimit, 4*PTlimit, 4*PTlimit);
	run("Draw", "slice");
	imageCalculator("AND create", "Cell","Tway");
	run("Analyze Particles...", "size=0-20000 circularity=0-1.00 show=Nothing display clear");
	makeSelection("angle",newArray(getResult("X", 0),xCorner,getResult("X", 1)),newArray(getResult("Y", 0),yCorner,getResult("Y", 1)));
	run("Measure");
	angle= getResult("Angle", 2);
	run("Clear Results");
	close("Result of Cell");
	return angle
}


function nbMblat(Index1, Index2, x ){

	return newArray(abs((Index1+x.length)-(Index2+x.length)),abs((Index1+x.length)-(Index2+x.length)),abs((Index1)-(Index2)),abs((Index1)-(Index2+x.length)));
		}
	
function num2array(str,delim){
	arr = split(str,delim);
	for(i=0; i<arr.length;i++) {
		arr[i] = parseInt(arr[i]);
	}

	return arr;
}