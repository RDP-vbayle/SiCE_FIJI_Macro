Dialog.create("SiCE FluoPapilla analysis Macro");
	Dialog.addMessage("This macro quantifies ROI fluorescence around contact point \n ");
	Dialog.addNumber("ROI zone lenght",25, 1,3, "pixels");
	Dialog.addNumber("ROI zone thickness",10, 1,3, "pixels");
	Dialog.addCheckbox("Scaled images?", true);
	Dialog.addChoice("Projection method", newArray("AVG", "MAX", "SUM"));
	Dialog.show();
	zone = Dialog.getNumber();
	mbt = Dialog.getNumber();
	scal=Dialog.getCheckbox();
	Proj = Dialog.getChoice();
	
run("Colors...", "foreground=white background=black selection=red");

if (scal==true)
		{
			run("Set Scale...", "distance=0 known=0 pixel=1 unit=pixel");
		}

title=getTitle();
getDimensions(width, height, channels, slices, frames);
newImage("papilla", "8-bit black", width, height, 1);
newImage("Control zones", "8-bit black", width, height, 1);
selectWindow(title);
run("Clear Results");
roiManager("reset");

if (Proj=="AVG")
		{
		run("Z Project...", "projection=[Average Intensity]");
		}

if (Proj=="MAX")
		{
		run("Z Project...", "projection=[Max Intensity]");
		}

if (Proj=="SUM")
		{
		run("Z Project...", "projection=[Sum Slices]");
		}
	
// Fit papilla cells within a polygon . Add to ROI manager

	run("Set Measurements...", "area mean centroid perimeter integrated redirect=None decimal=3");
	selectWindow(Proj+"_"+title);
	setTool("polygon");
	resetMinAndMax();
	waitForUser("Draw papilla cell contour");
	run("Area to Line");
	run("Fit Spline");
	run("Measure");
	perim = getResult("Perim.", 0);
	nbROIToT = perim/mbt;
	
run("Set Measurements...", "mean centroid integrated redirect=None decimal=3");

roiManager("Add");
selectWindow("papilla");
roiManager("Select", 0);
run("Fill");


selectWindow(Proj+"_"+title);
roiManager("Select", 0);
getSelectionCoordinates(xx, yy);
dist_ = newArray(xx.length);
distpoint = round(perim/xx.length);

run("Clear Results");

					if (zone == 0)
					{
					roiManager("reset");
					run("Split Channels");
					selectWindow("C2-"+Proj+"_"+title);
					run("Close");
					Xbas = xx[0];
					Ybas = yy[0];
					
					for(i=0; i<=xx.length-1; i++)
							{
					dist =sqrt( pow( (Xbas - xx[i]),2) + pow( (Ybas - yy[i]),2) );
					
							if (dist >= mbt)
								{
							makeOval(xx[i]-((mbt)/2), yy[i]-((mbt)/2), mbt, mbt);
							roiManager("Add");
							Xbas = xx[i];
							Ybas = yy[i];
							    }
							}
							roiManager("Show All");
							roiManager("multi-measure measure_all");
							for (i=0; i<roiManager("count"); i++) 
							{
							selectWindow("Control zones");
							roiManager("select", i);
							run("Fill");
							 }
				selectWindow("C1-"+Proj+"_"+title);
				run("8-bit");
				run("Merge Channels...", " c2=[Control zones] c3=papilla c4=C1-"+Proj+"_"+title+" create ignore");
				IJ.renameResults("Control ROIs");
				selectWindow("Composite");
				rename("Summary stack"+title);
						    }						   
				
	else
				{		
		newImage("Contact point", "8-bit black", width, height, 1);
		newImage("Contact zones", "8-bit black", width, height, 1);
		selectWindow(Proj+"_"+title);
		
		distzone_ = newArray(zone/distpoint);
		
		selectWindow(title);
		setTool("multipoint");
		roiManager("select", 0);
		waitForUser("Determine contact point");
		run("Measure");
		xCont = getResult("X", 0);
		yCont = getResult("Y", 0);
		roiManager("reset");

		selectWindow(Proj+"_"+title);
		run("Split Channels");
		selectWindow("C2-"+Proj+"_"+title);
		run("Close");
		
		///Calcul distances contact vs reste
		roiManager("reset");
		
		for(i=0; i<=(xx.length-1); i++)
				{			
		dist_[i] =sqrt( pow( (xx[i] - xCont),2) + pow( (yy[i] - yCont),2) );
			}
		Array.getStatistics(dist_, distMin, distMax, mean, stdDev);
		Indices = indexOfArray(dist_, distMin);
		Imin = Indices[0];

		////Calcul ROIs dans la zone de contact
		
		XRoiContInf = newArray(xx.length);
		YRoiContInf = newArray(xx.length);
		XRoi = newArray(xx.length);
		YRoi = newArray(xx.length);
		n =0;
		m =0;
		klimit = round((zone/2)-mbt/2);
		
		//// ajout point de contact
		
		makeOval(xx[Imin]-((mbt)/2), yy[Imin]-((mbt)/2), mbt, mbt);
		roiManager("Add");
		selectWindow("Contact point");
		roiManager("Select", 0);
		run("Fill");
		
		selectWindow("C1-"+Proj+"_"+title);
		roiManager("reset");


		////Calcul des coordonnées des ROIs autour de la papille
		
		for(k=0; k<=xx.length-1; k++)
			{
		dist_=sqrt( pow( (xx[k] - xx[Imin]),2) + pow( (yy[k] - yy[Imin]),2) );

//// Si ROI proche point de contact  alors ROI zone de contact

			if (dist_ <=klimit)
			{
			XRoiContInf [n] = xx[k];
			YRoiContInf [n] = yy[k];
			n= n+1;
			}
			
//// Si ROI loin  point de contact  alors ROI hors zone de contact

			if (dist_ >=klimit+mbt/2)
			{
			XRoi [m] = xx[k];
			YRoi [m] = yy[k];
			m= m+1;
			}
			}
			
		XRoicontBas = XRoiContInf[0];
		YRoicontBas = YRoiContInf[0];	
		Xbas = XRoi[0];
		Ybas = YRoi[0];


////Calcul ROIs dans la zone de contact
		
		makeOval(XRoicontBas-((mbt)/2), YRoicontBas-((mbt)/2), mbt, mbt);
		roiManager("Add");
			
		for(p=0; p<=n-1; p++)
						{
				dist =sqrt( pow( (XRoicontBas - XRoiContInf[p]),2) + pow( (YRoicontBas - YRoiContInf[p]),2) );

						if (dist >= mbt)
							{
						makeOval(XRoiContInf[p]-((mbt)/2), YRoiContInf[p]-((mbt)/2), mbt, mbt);
						roiManager("Add");
						XRoicontBas = XRoiContInf[p];
						YRoicontBas = YRoiContInf[p];
						 
						}
						}
						selectWindow("C1-"+Proj+"_"+title);
						roiManager("Show All");
							roiManager("multi-measure measure_all");
							IJ.renameResults("Contact ROIs");
							for (i=0; i<roiManager("count"); i++) 
							{
							selectWindow("Contact zones");
							roiManager("select", i);
							run("Fill");				   
						    }

				
		roiManager("reset");

			////Calcul ROIs hors de la zone de contact

		makeOval(Xbas-((mbt)/2), Ybas-((mbt)/2), mbt, mbt);
		roiManager("Add");
		
				for(o=0; o<=m-1; o++)
						{
				dist =sqrt( pow( (Xbas - XRoi[o]),2) + pow( (Ybas - YRoi[o]),2) );		
						if (dist >= mbt)
							{
						makeOval(XRoi[o]-((mbt)/2), YRoi[o]-((mbt)/2), mbt, mbt);
						roiManager("Add");
						Xbas = XRoi[o];
						Ybas = YRoi[o];
							}				   
						    }
						    
				selectWindow("C1-"+Proj+"_"+title);
				roiManager("Show All");
				roiManager("multi-measure measure_all");
				IJ.renameResults("Control ROIs");
				for (i=0; i<roiManager("count"); i++) 
				{
				selectWindow("Control zones");
				roiManager("select", i);
				run("Fill");				   
				}

				//// merge des différents compartiments

				
selectWindow("C1-"+Proj+"_"+title);
run("8-bit");									
run("Merge Channels...", "c1=[Contact point] c2=[Control zones] c3=papilla c4=C1-"+Proj+"_"+title+" c7=[Contact zones] create ignore");
selectWindow("Composite");
rename("Summary stack"+title);
						}
						
function indexOfArray(dist_, distMin) {
    count=0;
    for (j=0; j<lengthOf(dist_); j++) {
        if (dist_[j]==distMin) {
            count++;
        }
    }
    if (count>0) {
        indices=newArray(count);
        count=0;
        for (j=0; j<lengthOf(dist_); j++) {
            if (dist_[j]==distMin) {
                indices[count]=j;
                count++;
            }
        }
        return indices;
    } 