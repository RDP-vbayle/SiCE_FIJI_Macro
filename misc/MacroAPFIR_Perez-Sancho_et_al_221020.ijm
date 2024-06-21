///////Macro pour la quantif MCTP6 WT & mutant sac7 adpated from MacroAngleRoot_220523.ijm .

///Creation du tableau de résultat
	title1 = "[Result segmentation:]"; 
	f=title1; 
	run("New... ", "name="+title1+" type=Table");
	print(f,"\\Headings: Image name \tCell number\tCell file \t Cell Area \t Apical mb length \t Basal membrane length \t Basal vs apical distance \t Lateral Mb Left 1\t Lateral Mb Left 2\t Lateral Mb Left 3\t Lateral Mb Left 4\t TWJunction 1\t TWJunction 2\t TWJunction 3\tLateral Mb Right 1\t Lateral Mb Right 2\t Lateral Mb Right 3\t Lateral Mb Right 4\t  TWJunction 1\t TWJunction 2\t TWJunction 3\tCentroids axis Angle \t Upper_left angle \t Upper_right angle \t Lower_right angle \t Lower_left angle");
	title2 = "[Result Fluorescence:]"; 
	g=title2; 
	run("New... ", "name="+title2+" type=Table");
	print(g,"\\Headings: Image name \tCell number\t Cell file \t Cell file type \t Intracellular fluorescence \t Mb fluorescence \t Apical mb fluorescence \t Basal membrane fluorescence  \t Basal bis   \t corner 1 \t corner 2 \t corner 3 \t corner 4 \t corner 5 \t corner 6 \t corner 7 \t corner 8");
	
dir1 = getDirectory("Choose Source Directory ");
list = getFileList(dir1);
saveDir = dir1 + File.separator + "Analysed"+File.separator;
File.makeDirectory(saveDir);
print(saveDir);
print(list.length);

for (file=0; file<list.length; file++) {
	    showProgress(file+1, list.length);
	    print("i "+file+"_"+list[file]);
	    
	if(endsWith(list[file], ".nd")){
	    open(dir1+list[file]);
	///get scale:
		getPixelSize (unit, pixelWidth, pixelHeight);
		if (unit!="pixel"){
		xPIX=pixelWidth;}
		else exit ("No calib");
		getDimensions(width, height, channels, slices, frames);
		
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
		
		 do {
		setOption("BlackBackground", true);
		roiManager("Reset");
		run("Clear Results");
		roiManager("reset");
		run("Remove Overlay");
		setOption("ExpandableArrays", true);
		run("Overlay Options...", "stroke=Red width=0 fill=Red set");
		run("Roi Defaults...", "color=red stroke=0 group=0");
		run("Set Measurements...", "area mean centroid center fit shape stack redirect=None decimal=3");
		title=getTitle();
		 	
		///rotation
			run("Select All");
			if (slices>1){
			run("Z Project...", "projection=[Sum Slices]");}
			else{
			run("Duplicate...", " ");
			}
			rename("Z");
			run("Gaussian Blur...", "sigma=20 ");
			setAutoThreshold("Default dark no-reset");
			//run("Threshold...");
			setOption("BlackBackground", true);
			run("Convert to Mask");
			run("Fill Holes");
			doWand(width/2, height/2);
			run("Measure");
			angl= -90+getResult("Angle", 0);
			close("Z");
			selectWindow(title);
			run("Rotate... ", "angle="+angl+" grid=1 interpolation=Bilinear fill stack");
		
		
		run("Set Scale...", "distance=0 known=0 pixel=1 unit=pixel");
		
		
		////choix des paramètres
		
			Dialog.create("SiCE MacroRoot");
			Dialog.addMessage("  \n ");
			Dialog.addCheckbox("Correct rotation?", true);
			Dialog.addCheckbox("Correct orientation?", true);
			Dialog.addCheckbox("Global Three way junctions analysis? ie independently of cell", false);
			Dialog.addMessage("		Cell segmentation parameters: \n ");
			Dialog.addNumber("Min Cell size",500, 1,5, "pixels^2");
			Dialog.addNumber("Max Cell size",200000, 1,5, "pixels^2");
			Dialog.addNumber("Distance Map noise",5, 1,2, " between 3 and 10");
			Dialog.addCheckbox("Manual cell removal?", true);
			Dialog.addMessage("		Edges detection parameters: \n ");
			Dialog.addNumber("Cell file Minimal distance",20, 1,2, "pixels inbetween two cell files");
			Dialog.addNumber("Minimal distance between points",5, 1,2, "pixels");
			Dialog.addMessage("		Fluorescence measurements parameters: \n ");
			Dialog.addNumber(" Mb width ",2, 1,2, "pixels");
			Dialog.addNumber(" Junction ROI diameter for measurements",3, 1,2, "pixels");
			Dialog.show();
			rot=Dialog.getCheckbox();
			ori=Dialog.getCheckbox();
			Tway=Dialog.getCheckbox();
			CellMin = Dialog.getNumber();
			CellMax = Dialog.getNumber();
			Noiz = Dialog.getNumber();
			remov=Dialog.getCheckbox();
			CFlimt=Dialog.getNumber();
			PTlimit=Dialog.getNumber();
			MbW=Dialog.getNumber();
			Jdia=Dialog.getNumber();
		 } while (rot==false);
		
		if (Tway==true){
			g = "[Three way junctions summary:]"; 
			run("New... ", "name="+g+" type=Table");
			print(g,"\\Headings: Image name \t Junction number\t TWJ X \t TWJ Y \t Angle1 \t Angle2 \t Angle3");
			}
			
		if (ori==false)
					{
		run("Rotate... ", "angle=180 grid=1 interpolation=Bilinear fill stack");				
					}
					
		/// background removal
			run("Subtract Background...", "rolling=50");
				
		/// Plane slection
			setTool("rectangle");
			waitForUser("Select Z/ crop if needed");
			getSelectionBounds(xCROP, yCROP, widthCROP, heightCROP);
			run("Select None");
			Zslice=getSliceNumber();
			run("Despeckle", "slice");
			run("Despeckle", "slice");	
			run("Duplicate...","channels=1 duplicate range="+Zslice+"-"+Zslice+"");
			rename("cells");
			
		setBatchMode(true);
		
		///Cell segmentation
		
			//Wavelet filtering
			run("Duplicate...", " ");
					run("Unsharp Mask...", "radius=3 mask=0.9");
					rename("mb");			
						
			//Tresholding	
					setAutoThreshold("Percentile dark no-reset");		
					run("Convert to Mask");	
					run("Duplicate...", " ");
					run("Invert");
					run("Fill Holes");
					
			//Markerbased Watershed
					run("Distance Map");
					run("Find Maxima...", "noise="+Noiz+" output=[Single Points]");
					run("Marker-controlled Watershed", "input=cells marker=[mb-1 Maxima] mask=None compactness=0 binary calculate use");			
					close("mb-1 Maxima");
					run("8-bit");
					setThreshold(2, 255, "raw");
					run("Convert to Mask");
					close("mb-1");
					close("mb");
		
			// Make the CROP					
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
					selectWindow(title);				
					Stack.setChannel(2);
					makeRectangle(xCROP, yCROP, widthCROP, heightCROP);
					run("Duplicate...", "title=fluo");
					rename("fluo");		
					selectWindow("cells");			
					makeRectangle(xCROP, yCROP, widthCROP, heightCROP);
					run("Crop");	
					roiManager("Show All");
					waitForUser("Remove Aberrant segmented cells");
					}
					nROIs = roiManager("count");
			
			/// Cellfile type
			CelltypeAdj= "Tricho";
			Dialog.create("Cell file type selection:");
			Dialog.addChoice(" ", newArray("Tricho","Atricho"));
			Dialog.addMessage("select for Cell file 1 ");
			Dialog.show();				
			Celltype = Dialog.getChoice();			
			if (Celltype=="Tricho") {
			CelltypeAdj= "Atricho";	
			}	
setBatchMode(true);		
			
			Xcent= newArray; // Cells centroids X coordinate array
			Ycent= newArray; // Cells centroids Y coordinate array
			Area= newArray;
			Fluocyto= newArray; // cytosolic fluorescence 
			FluoMB= newArray;	// whole membrane fluorescence 
			Xtway=newArray();
			Ytway=newArray();
			XtwayPot=newArray();
			YtwayPot=newArray();
		
			run("Clear Results");
			
		selectWindow("fluo");
		
		////Loop cell analysis
		
		for(l=0; l<=nROIs-1; l++)
					{	
				// Mesure centroid and area
						roiManager("Select", l);
						run("Measure");
						Xcent[l]=  getResult("X",0);
						Ycent[l]=  getResult("Y",0);
						Area[l]= getResult("Area", 0)*(pow(xPIX,2));
						run("Enlarge...", "enlarge=-2");
						run("Measure");
						Fluocyto[l]= getResult("Mean", 1);
						roiManager("Select", l);
						run("Make Band...", "band="+MbW);
						run("Measure");
						FluoMB[l]= getResult("Mean", 2);
						run("Clear Results");
					}
									
			// Cell file identification		
				///Cell nb sorting according X centroid
					sortedXcent = Array.copy(Xcent);
					Array.sort(sortedXcent);
					rankPosArr = Array.rankPositions(Xcent);
					CF=1;
					cellFile=newArray;
					CFP=newArray;
				
		for (cc=0; cc<nROIs-1; cc++){
						cellFile[rankPosArr[cc]]=CF;
						centDist =sortedXcent[cc+1] - sortedXcent[cc];
		
					if (centDist>=CFlimt)
						{
							CF=CF+1;
						}
									}
			
			cellFile[rankPosArr[cc]]=CF;	
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
						selectWindow("Tagged skeleton"); // Tagged skeleton is the image wher all edges are segmented
						setThreshold(48, 94, "raw");
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
			
						newImage("Cell", "8-bit black", widthCROP, heightCROP, 1); // Cell will be the temp image to identify ROIs
						
		for(l=0; l<=nROIs-1; l++)
			{									
				x=newArray();	
				y=newArray();	
								
				selectWindow("Cell");
				roiManager("Show None");
				run("Select All");
				run("Clear", "slice");	
				roiManager("select", l);
				run("Enlarge...", "enlarge=1");
				run("Draw");				
				imageCalculator("AND create", "Cell","Tagged skeleton");						
								
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
				getSelectionCoordinates(xx, yy);
				run("Select All");
				run("Clear Results");
						
		//// HR highRight, HL highLeft, LL, lowLeft, LR lowRigh, Correlation made between convex hull point and rectangle fitting		
			indexHR= Corneridentif(xx, yy, widthCROP, 0);
			indexHL= Corneridentif(xx, yy, 0, 0);
			indexLL= Corneridentif(xx, yy, 0, heightCROP);
			indexLR= Corneridentif(xx, yy, widthCROP, heightCROP);
			
			indexHR= Corneridentif(x, y, xx[indexHR], yy[indexHR]);
			indexHL= Corneridentif(x, y, xx[indexHL], yy[indexHL]);
			indexLL= Corneridentif(x, y, xx[indexLL], yy[indexLL]);
			indexLR= Corneridentif(x, y, xx[indexLR], yy[indexLR]);
		
		//// Angles measurements
		
			AngleCoin2= AngleCorner(x[indexHR], y[indexHR], PTlimit);	
			AngleCoin1= AngleCorner(x[indexHL], y[indexHL], PTlimit);
			AngleCoin4= AngleCorner(x[indexLL], y[indexLL], PTlimit);	
			AngleCoin3= AngleCorner(x[indexLR], y[indexLR], PTlimit);			
			selectWindow("Cell");
			run("Clear", "slice");	
			selectWindow("cells");
			
		//// Lateral mb measurements
		
			xB= Array.concat(x,x,x);
			yB= Array.concat(y,y,y);
			LmbL= newArray(NaN,NaN,NaN,NaN);
			LmbR= newArray(NaN,NaN,NaN,NaN);
			TWJL= newArray(NaN,NaN,NaN);
			TWJR= newArray(NaN,NaN,NaN);
			EdgeFluo=newArray(NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN);
			
		//nb mb laterale gauche + three way junction
		
			nb= nbMblat(indexHL, indexLL, x);
			Array.getStatistics(nb, min, max, mean, stdDev);
			mbLatLnb=min;
			rankNb=Array.rankPositions(nb); 
			for (p = 0; p < mbLatLnb; p++) {	
			makeLine(xB[indexHL+p], yB[indexHL+p], xB[indexHL+p+1], yB[indexHL+p+1]);	
			run("Measure");
			LmbL[p]= getResult("Length", p);
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
			LmbR[p]= getResult("Length", p);
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
			
			selectWindow("fluo");
			
		////////definition membrane apicale: XHmb & YHmb center of mb
				makeLine(x[indexHR], y[indexHR], x[indexHL], y[indexHL]);
				run("Properties... ", "  width="+MbW);
		//		run("Overlay Options...", "stroke=none width=0 fill=Red set");
		//		run("Add Selection...");
				run("Measure");
				XHmb=getResult("X", 0);
				YHmb=getResult("Y", 0);
				fluoHmb=getResult("Mean", 0);
				Hmb=sqrt(pow((x[indexHR]-x[indexHL]),2)+pow((y[indexHR]-y[indexHL]),2));
							
		//////definition de la membrane basale: XLmb & YLmb center of mb
				makeLine(x[indexLR], y[indexLR], x[indexLL], y[indexLL]);
				run("Properties... ", "  width="+MbW);
		//		run("Overlay Options...", "stroke=none width=0 fill=Red set");
		//		run("Add Selection...");
				run("Measure");
				Xlmb=getResult("X", 1);
				Ylmb=getResult("Y", 1);
				fluoLmb=getResult("Mean", 1);
				Lmb=sqrt(pow((x[indexLR]-x[indexLL]),2)+pow((y[indexLR]-y[indexLL]),2));
				
		///// length between apical and basal mb		
				DistMb=sqrt(pow((Xlmb-XHmb),2)+pow((Ylmb-YHmb),2));
				
		///// angle between basal mb and cell centroid	
				selectWindow("cells");		
				makeSelection("angle",newArray(x[indexLL],Xlmb,Xcent[l]),newArray(y[indexLL],Ylmb,Ycent[l]));
				run("Overlay Options...", "stroke=none width=0 fill=Blue set");
				run("Add Selection...");
				run("Measure");
				angleCent= getResult("Angle", 2);
				run("Clear Results");
				MbSeg=NaN;
				
			if(l<=nROIs-2){
		MbSeg=Membranes(cellFile, nROIs, l );
				}
				run("Clear Results");
		//setBatchMode("exit and display");			
			 edgeNb=Edges(EdgeFluo,Jdia,l);
			 CT=CellT(Celltype, CelltypeAdj,l,cellFile);
			 
				print(g,title+"\t"+(l+1)+"\t"+cellFile[l]+"\t"+CT+"\t"+Fluocyto[l]+"\t"+FluoMB[l]+"\t"+fluoHmb+"\t"+fluoLmb+"\t"+MbSeg+"\t"+EdgeFluo[0]+"\t"+EdgeFluo[1]+"\t"+EdgeFluo[2]+"\t"+EdgeFluo[3]+"\t"+EdgeFluo[4]+"\t"+EdgeFluo[5]+"\t"+EdgeFluo[6]+"\t"+EdgeFluo[7]);
				print(f,title+"\t"+(l+1)+"\t"+cellFile[l]+"\t"+Area[l]+"\t"+Hmb*xPIX+"\t"+Lmb*xPIX+"\t"+DistMb*xPIX+"\t"+LmbL[0]+"\t"+LmbL[1]+"\t"+LmbL[2]+"\t"+LmbL[3]+"\t"+TWJL[0]+"\t"+TWJL[1]+"\t"+TWJL[2]+"\t"+LmbR[0]+"\t"+LmbR[1]+"\t"+LmbR[2]+"\t"+LmbR[3]+"\t"+TWJR[0]+"\t"+TWJR[1]+"\t"+TWJR[2]+"\t"+angleCent+"\t"+AngleCoin1+"\t"+AngleCoin2+"\t"+AngleCoin3+"\t"+AngleCoin4);
							}
							
		close("Results");
		selectWindow("cells");
		roiManager("Show All");
		saveAs("TIFF", saveDir+title+"_cells");
		selectWindow("fluo");
		Overlay.show;
		saveAs("TIFF", saveDir+title+"_fluo");
		close("*");
		roiManager("reset");
		}
		setBatchMode(false);
		}
		}
	selectWindow("Result Fluorescence:");
	saveAs("Text", dir2+"Result Fluorescence.csv");
	selectWindow("Result segmentation:");
	saveAs("Text", dir2+"Result segmentation.csv");

function Corneridentif(Xcoin, Ycoin, X0, Y0 ){
		TLC= newArray;
	for (ii=0; ii<=Ycoin.length-1; ii++){
		TLC[ii]=sqrt( pow( (X0 - Xcoin[ii]),2) + pow( (Y0 - Ycoin[ii]),2) );
		Array.getStatistics(TLC, min, max, mean, stdDev);		
		}
	for (k=0; k<TLC.length; k++){
          if (TLC[k]==min) return k;
          };
		return k;
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

function Membranes(cellFile, nROIs, l ){
	selectWindow("Cell");
	roiManager("Show None");
	roiManager("select", l);
	run("Enlarge...", "enlarge=1");
	run("Draw");
	m=l;

	loop=true;
do{
	m++;
	if (m>=nROIs-1){
		loop=false;
	}
	if(cellFile[m]==cellFile[l]){
		loop=false;
	roiManager("select", m);
	run("Enlarge...", "enlarge=1");
	run("Make Inverse");
	run("Clear", "slice");	
	run("Select None");
	run("Analyze Particles...", "size=0-20000 display add");
	if (getValue("results.count")==1){
		run("Select All");
		run("Clear");
		selectWindow("fluo");
		roiManager("Show None");
		roiManager("select", roiManager("count")-1);
		run("Measure");
		run("Enlarge...", "enlarge=1");
		run("Overlay Options...", "stroke=none width=0 fill=Orange set");
		run("Add Selection...");		
		MbSeg= getResult("Mean", 1);
		roiManager("select", nROIs);
		roiManager("Delete");
		}
	}
}while (loop==true)	
	return MbSeg;
		}	


function Edges(EdgeFluo,Jdia,l){
	selectWindow("Cell");
	roiManager("Show None");
	run("Select All");
	run("Clear", "slice");	
	roiManager("select", l);
	run("Enlarge...", "enlarge=1");
	run("Draw");
	imageCalculator("AND create", "Cell","Tagged skeleton");
	selectWindow("Result of Cell");
	run("Analyze Particles...", "size=0-20000 display add");
	close();
	selectWindow("fluo");	
	Overlay.hide;
	roiManager("Show None");
	edgeNb= getValue("results.count");
	for (n = 0; n <= edgeNb-1; n++) {
		roiManager("select", nROIs);
		run("Measure");
		makeOval(getResult("X", edgeNb+n)-Jdia/2, getResult("Y", edgeNb+n)-Jdia/2, Jdia, Jdia);
		run("Measure");
		EdgeFluo[n]=getResult("Mean", edgeNb+n+1);
	roiManager("select", nROIs);
	roiManager("Delete");
	}
	return edgeNb;
}


function CellT(Celltype, CelltypeAdj,l,cellFile)
{
	if (cellFile[l] % 2) {
	CT=Celltype;
}
else {
	CT=CelltypeAdj;
}
return CT;
}