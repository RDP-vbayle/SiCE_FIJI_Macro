// INPUT files, two channel images.
// Additional plugin needed: https://imagej.net/plugins/distance-transform-watershed
	
	
	
	setOption("BlackBackground", true);
	run("Roi Defaults...", "color=green stroke=0 group=0");
	roiManager("Reset");
	run("Clear Results");
	run("Remove Overlay");
	setOption("ExpandableArrays", true);
	run("Set Measurements...", "area mean centroid center fit shape stack feret's redirect=None decimal=3");
	run("Select None");

/// Parameter selection

	Dialog.create("INPUT parameters:");
	Dialog.addNumber("Layer number? ",5);
	Dialog.addMessage("	Cell segmentation parameters: \n ");
	Dialog.addNumber("		Rolling background ",50);
	Dialog.addMessage("	CellWall selection parameters: \n ");
	Dialog.addNumber("		Enlargement factor ",1);
	Dialog.show();
	
	Lnb = Dialog.getNumber();
	RB = Dialog.getNumber();
	Ero = Dialog.getNumber();


///Result table 

	title1 = "[Result summary:]"; 
	f=title1; 
	run("New... ", "name="+title1+" type=Table");
	print(f,"\\Headings: Image name \t Cell Layer\t Cell number \t Cell Area \t Major Axis \t Minor Axis \t Circ. \t Round");

	name= getTitle();
	selectWindow(name);
		
	run("Duplicate...", "duplicate");
	lenght=lengthOf(name);
	title=substring(name, 0, lenght-4 );
	rename ("temp");
	run("Split Channels");
	close("C2-temp");
	selectWindow("C1-temp");
	run("Duplicate...", "duplicate");	
	rename("mb");	    
    run("Set Scale...", "distance=0 known=0 pixel=1 unit=pixel global");
	
/// Cell segmentation using Distance Transform Watershed 

setBatchMode(true);	
						    run("Subtract Background...", "rolling="+RB+"");
							run("Unsharp Mask...", "radius=5 mask=0.60");
							setAutoThreshold("Otsu dark");
							setOption("BlackBackground", true);
							run("Convert to Mask");
							run("Invert");
							run("Erode");
							run("Dilate");				
							run("Distance Transform Watershed", "distances=[Chessknight (5,7,11)] output=[16 bits] normalize dynamic=3 connectivity=8");			


setBatchMode(false);
							run("Merge Channels...", "c1=C1-temp c2=mb-dist-watershed create");
							Stack.setChannel(2);
							run("Grays");
							close("mb");
							
/// Cell selection and measurements

			Celllayer=newArray();
			CellArea=newArray();
			CellMajAx=newArray();
			CellMinAx=newArray();
			CellCirc=newArray();
			CellRound=newArray();
			CellNumber=newArray(4);
			color=newArray("orange","blue","yellow","green","red");
							
	for (i = 0; i < Lnb; i++) {
		run("Select None");	
		Roibasal=roiManager("Count"); 
		Layer="Layer_"+(i+1);
		selectWindow("temp");
		Stack.setChannel(2);
		setTool("wand");
		run("Tile");
		waitForUser("Select Cells and add to manager "+Layer);	
		totRois=roiManager("Count");
		CellNumber[i]= totRois-Roibasal;
		run("Clear Results");
		p=0;
		for (n = Roibasal; n <= totRois-1; n++) {
			Celllayer[n]=Layer;
			selectWindow("temp");
			roiManager("select", n);
			run("Enlarge...", "enlarge=1");
			run("Enlarge...", "enlarge=-1");
			run("Fill", "slice");
			roiManager("update");
			run("Interpolate", "interval=1 smooth adjust");
			run("Enlarge...", "enlarge="+Ero);
			run("Measure");
			CellArea[n]=getResult("Area", p);
			CellMajAx[n]=getResult("Major", p);
			CellMinAx[n]=getResult("Minor", p);
			CellCirc[n]=getResult("Circ.", p);
			CellRound[n]=getResult("Round", p);
			roiManager("Set Color",color[i]);
			run("Add Selection...");
			p++;
		}
		}
	for (m = 0; m < totRois; m++) {
		print(f, title+"\t"+ Celllayer[m] +"\t"+m+1+"\t"+CellArea[m]+"\t"+CellMajAx[m]+"\t"+CellMinAx[m]+"\t"+CellCirc[m]+"\t"+CellRound[m]);			
		}
		roiManager("reset");
		run("To ROI Manager");
		run("Green");
		close("temp");
		run("From ROI Manager");	
		