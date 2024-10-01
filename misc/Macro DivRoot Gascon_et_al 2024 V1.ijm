///////Macro for features extraction of Root tissues (mb size, angles, etc...)
///// Prerequisite: Wavelet_A_trou that must be copied in your FIJI/plugin folder &  Distance Based Watershed part of the MorphoLibJ library
///// INPUT: Single channel images (Z- stacks allowed) of Arabidopsis root cells showing membrane fluorescence



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

///Manual rotation of the image to align the root with vertical axis

setBatchMode("exit and display");
		setTool("line");
		run("Enhance Contrast", "saturated=0.35");
		waitForUser("Draw cell axis from top to bottom");
		resetMinAndMax();
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
		run("Set Scale...", "distance=0 known=0 pixel=1 unit=pixel");
	
////Parameters selection

	Dialog.create("SiCE DivMacroRoot");
	Dialog.addMessage("  \n ");
	Dialog.addCheckbox("Paired cells analysis?", true);
	Dialog.addCheckbox("Global Three way junctions analysis?", true);
	Dialog.addMessage("		Cell segmentation parameters: \n ");
	Dialog.addNumber("Min Cell size",100, 1,5, "pixels^2");
	Dialog.addNumber("Max Cell size",20000, 1,5, "pixels^2");
	Dialog.addNumber("Wavelet plane",2, 1,5, " 2 to 4 ");
	Dialog.addNumber("Distance Map noise",2, 1,2, " "); 
	Dialog.addCheckbox("Manual cell removal?", true);
	Dialog.addMessage("		Edges detection parameters: \n ");
	Dialog.addNumber("Cell file Minimal distance",30, 1,2, "pixels");
	Dialog.addNumber("Minimal distance to measure corners",5, 1,2, "pixels");
	Dialog.show();
	Simp=Dialog.getCheckbox();
	Tway=Dialog.getCheckbox();
	CellMin = Dialog.getNumber();
	CellMax = Dialog.getNumber();
	wave = Dialog.getNumber();
	Noiz = Dialog.getNumber();
	remov=Dialog.getCheckbox();
	CFlimt=Dialog.getNumber();
	PTlimit=Dialog.getNumber();
	
if (Tway==true){
	g = "[Three way junctions summary:]";
	run("New... ", "name="+g+" type=Table");
	print(g,"\\Headings: Image name \t Junction number\t Junction Type \t TWJ X \t TWJ Y \t Angle1 \t Angle2 \t Angle3 \t Angle4");
	}	
	
if (Simp==false){
	f="[Result summary:]";
	run("New... ", "name="+f+" type=Table");
	print(f,"\\Headings: Image name \tCell number\t Cell file \t Cell Area \t Apical mb length \t Basal membrane length \t Basal vs apical distance \t Lateral Mb Left 1\t Lateral Mb Left 2\t Lateral Mb Left 3\t Lateral Mb Left 4\t TWJunction 1\t TWJunction 2\t TWJunction 3\tLateral Mb Right 1\t Lateral Mb Right 2\t Lateral Mb Right 3\t Lateral Mb Right 4\t  TWJunction 1\t TWJunction 2\t TWJunction 3\tCentroids axis Angle \t Upper_left angle \t Upper_right angle \t Lower_right angle \t Lower_left angle");	
	}
	

/// background removal
	run("Subtract Background...", "rolling=50 stack");

/// Plane selection
	setTool("rectangle");
	waitForUser("Select Z & crop if needed");
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
			}

if (Simp==true){
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
	pbDiv=false;	
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

if (Simp==false){
for(l=0; l<=nROIs-1; l++)
	{
		centMbX=newArray();
		centMbY=newArray();
		MbSize=newArray();
		selectWindow("mb");
		run("Duplicate...", " ");
		rename("tempMb");
		roiManager("select", l);
		run("Enlarge...", "enlarge=1");
		run("Clear Outside");
		run("Analyze Skeleton (2D/3D)", "prune=none show");
		
		selectWindow("nodes");
		run("Duplicate...", " ");
		rename("tempNodes");
		roiManager("select", l);
		run("Enlarge...", "enlarge=3");
		run("Clear Outside");
		close("tempMb");
		close("Tagged skeleton");
		close("tempNodes");
		close("cells-"+l+1);
		
		IJ.renameResults("Branch information","Results");
		nMB=nResults;
		for (m = 0; m < nMB; m++) {
		MbSize[m]=getResult("Branch length", m);
		centMbX[m]=(getResult("V1 x", m)+getResult("V2 x", m))/2;
		centMbY[m]=(getResult("V1 y", m)+getResult("V2 y", m))/2;
	}
	
		x=newArray();
		y=newArray();

		selectWindow("Cell");
		roiManager("select", l);
		run("Enlarge...", "enlarge=1");
		run("Draw");	
		imageCalculator("AND create", "Cell","nodes");

		run("Analyze Particles...", "size=0-20000 display clear");
		for (k = 0; k < nResults; k++) {
		x[k]= getResult("X", k);
		y[k]= getResult("Y", k);
		}
		
		makeSelection("polygon",x, y);
		run("Convex Hull");
		getSelectionCoordinates(x, y);
		close("Result of Cell");
		selectWindow("Cell");
		roiManager("select", l);
		run("Fit Rectangle");
		run("Enlarge...", "enlarge=-2");		
		getSelectionCoordinates(xx, yy); ///Cells fitted with rectangle with xx and yy coordinates
		run("Select All");
		//run("Clear", "slice");
		run("Clear Results");

//// HR highRight, HL highLeft, LL, lowLeft, LR lowRigh
	indexHR= Corneridentif(xx, yy, widthCROP, 0);
	indexHL= Corneridentif(xx, yy, 0, 0);
	indexLL= Corneridentif(xx, yy, 0, heightCROP);
	indexLR= Corneridentif(xx, yy, widthCROP, heightCROP);

	indexHR= Corneridentif(x, y, xx[indexHR], yy[indexHR]);
	indexHL= Corneridentif(x, y, xx[indexHL], yy[indexHL]);
	indexLL= Corneridentif(x, y, xx[indexLL], yy[indexLL]);
	indexLR= Corneridentif(x, y, xx[indexLR], yy[indexLR]);

//// Calcul angles

	AngleCoin2= AngleCorner(x[indexHR], y[indexHR], PTlimit);
	AngleCoin1= AngleCorner(x[indexHL], y[indexHL], PTlimit);
	AngleCoin4= AngleCorner(x[indexLL], y[indexLL], PTlimit);
	AngleCoin3= AngleCorner(x[indexLR], y[indexLR], PTlimit);
	selectWindow("Cell");
	run("Clear", "slice");
	selectWindow("cells");

//// Calcul mb laterales
	xB= Array.concat(x,x,x);
	yB= Array.concat(y,y,y);
	LmbL= newArray(NaN,NaN,NaN,NaN);
	LmbR= newArray(NaN,NaN,NaN,NaN);
	TWJL= newArray(NaN,NaN,NaN);
	TWJR= newArray(NaN,NaN,NaN);

	//nb mb laterale gauche + three way junction

	nb= nbMblat(indexHL, indexLL, x);
	Array.getStatistics(nb, min, max, mean, stdDev);
	mbLatLnb=min;
	rankNb=Array.rankPositions(nb);
	for (p = 0; p < mbLatLnb; p++) {
		makeLine(xB[indexHL+p], yB[indexHL+p], xB[indexHL+p+1], yB[indexHL+p+1]);
		run("Measure");
		X= getResult("X", p);
		Y= getResult("Y", p);
		indexMB=Corneridentif(centMbX, centMbY, X, Y );
		LmbL[p]= MbSize[indexMB];
	}
	run("Clear Results");
	if (mbLatLnb>1) {
	for (p = 0; p < mbLatLnb-1; p++) {
		makeSelection("angle",newArray(xB[indexHL+p],xB[indexHL+p+1],xB[indexHL+p+2]),newArray(yB[indexHL+p],yB[indexHL+p+1],yB[indexHL+p+2]));
		run("Measure");
		makePoint(xB[indexHL+p+1],yB[indexHL+p+1], "medium yellow cross");
		run("Add Selection...");
		TWJL[p]= getResult("Angle", p);
	}
	}
	run("Clear Results");

	//nb mb laterale droite+ three way junction
	
	nb= nbMblat(indexLR, indexHR, x);
	Array.getStatistics(nb, min, max, mean, stdDev);
	mbLatRnb=min;
	rankNb=Array.rankPositions(nb);
	for (p = 0; p < mbLatRnb; p++) {
		makeLine(xB[indexLR+p], yB[indexLR+p], xB[indexLR+p+1], yB[indexLR+p+1]);
		run("Measure");
		X= getResult("X", p);
		Y= getResult("Y", p);
		indexMB=Corneridentif(centMbX, centMbY, X, Y );
		LmbR[p]= MbSize[indexMB];
	}
	run("Clear Results");
	if (mbLatRnb>1) {
	for (p = 0; p < mbLatRnb-1; p++) {
		makeSelection("angle",newArray(xB[indexLR+p],xB[indexLR+p+1],xB[indexLR+p+2]),newArray(yB[indexLR+p],yB[indexLR+p+1],yB[indexLR+p+2]));
		run("Measure");
		makePoint(xB[indexLR+p+1],yB[indexLR+p+1], "medium yellow cross");
		run("Add Selection...");
		TWJR[p]= getResult("Angle", p);
	}
	}
	run("Clear Results");
	
////////definition membrane apicale: XHmb & YHmb center of mb

		makeLine(x[indexHR], y[indexHR], x[indexHL], y[indexHL]);
		run("Measure");
		XHmb=getResult("X", 0);
		YHmb=getResult("Y", 0);
		indexHMB=Corneridentif(centMbX, centMbY, XHmb, YHmb );
		Hmb= MbSize[indexHMB];

//////definition de la membrane basale: XLmb & YLmb center of mb
		makeLine(x[indexLR], y[indexLR], x[indexLL], y[indexLL]);
		run("Overlay Options...", "stroke=none width=0 fill=Red set");
		run("Add Selection...");
		run("Measure");
		Xlmb=getResult("X", 1);
		Ylmb=getResult("Y", 1);
		indexLMB=Corneridentif(centMbX, centMbY, Xlmb, Ylmb );
		Lmb= MbSize[indexLMB];

///// length between apical and basal mb
		DistMb=sqrt(pow((centMbX[indexLMB]-centMbX[indexHMB]),2)+pow((centMbY[indexLMB]-centMbY[indexHMB]),2));

///// angle between basal mb and cell centroid
		makeSelection("angle",newArray(x[indexLL],Xlmb,Xcent[l]),newArray(y[indexLL],Ylmb,Ycent[l]));
		run("Overlay Options...", "stroke=none width=0 fill=Blue set");
		run("Add Selection...");
		run("Measure");
		angleCent= getResult("Angle", 2);

			print(f,title+"\t"+(l+1)+"\t"+cellFile[l]+"\t"+Area[l]+"\t"+Hmb*xPIX+"\t"+Lmb*xPIX+"\t"+DistMb*xPIX+"\t"+LmbL[0]+"\t"+LmbL[1]+"\t"+LmbL[2]+"\t"+LmbL[3]+"\t"+TWJL[0]+"\t"+TWJL[1]+"\t"+TWJL[2]+"\t"+LmbR[0]+"\t"+LmbR[1]+"\t"+LmbR[2]+"\t"+LmbR[3]+"\t"+TWJR[0]+"\t"+TWJR[1]+"\t"+TWJR[2]+"\t"+angleCent+"\t"+AngleCoin1+"\t"+AngleCoin2+"\t"+AngleCoin3+"\t"+AngleCoin4);
					
					}
}

close("Results");
selectWindow("cells");
roiManager("Show All");

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
					print(g,title+"\t"+(i+1)+"\t"+"3WJ"+"\t"+XtwayF[i]+"\t"+YtwayF[i]+"\t"+getResult("Angle", 3)+"\t"+getResult("Angle", 4)+"\t"+getResult("Angle", 5)+"\t"+"ND");
					selectWindow("cells");
					makePoint(XtwayF[i], YtwayF[i], "medium yellow cross");
					run("Add Selection...");

					}
					if (nResults==4){
					makeSelection("angle",newArray(getResult("X", 0),XtwayF[i],getResult("X", 1)),newArray(getResult("Y", 0),YtwayF[i],getResult("Y", 1)));
					run("Measure");
					makeSelection("angle",newArray(getResult("X", 0),XtwayF[i],getResult("X", 2)),newArray(getResult("Y", 0),YtwayF[i],getResult("Y", 2)));
					run("Measure");
					makeSelection("angle",newArray(getResult("X", 1),XtwayF[i],getResult("X", 3)),newArray(getResult("Y", 1),YtwayF[i],getResult("Y", 3)));
					run("Measure");
					makeSelection("angle",newArray(getResult("X", 3),XtwayF[i],getResult("X", 2)),newArray(getResult("Y", 3),YtwayF[i],getResult("Y", 2)));
					run("Measure");
					print(g,title+"\t"+(i+1)+"\t"+"4WJ"+"\t"+XtwayF[i]+"\t"+YtwayF[i]+"\t"+getResult("Angle", 4)+"\t"+getResult("Angle", 5)+"\t"+getResult("Angle", 6)+"\t"+getResult("Angle", 7));
					selectWindow("cells");
					makePoint(XtwayF[i], YtwayF[i], "medium blue cross");
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


if (Simp==true){
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
		print(d,title+"\t"+(i+1)+"\t"+idxCL[i]+"\t"+cellFile[idxCL[i]-1]+"\t"+Area[idxCL[i]-1]+"\t"+idxCR[i]+"\t"+cellFile[idxCR[i]-1]+"\t"+Area[idxCR[i]-1]+"\t"+DivLength*xPIX+"\t"+DivAngle);
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
		print(h,title+"\t"+(i+1)+"\t"+idxL[i]+"\t"+cellFile[idxL[i]-1]+"\t"+Area[idxL[i]-1]+"\t"+idxR[i]+"\t"+cellFile[idxR[i]-1]+"\t"+Area[idxR[i]-1]+"\t"+DivLength*xPIX+"\t"+DivAngle);
		close("Temp-2");
		close("Temp-1");
		close("Tagged skeleton");
	}
	}
}


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