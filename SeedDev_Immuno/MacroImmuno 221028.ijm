	setOption("BlackBackground", true);
	run("Roi Defaults...", "color=green stroke=0 group=0");
	roiManager("Reset");
	run("Clear Results");
	run("Remove Overlay");
	setOption("ExpandableArrays", true);
	run("Set Measurements...", "area mean centroid center fit shape stack feret's redirect=None decimal=3");
	run("Select None");

/// Selection paramètres

	Dialog.create("Immuno Macro");
	Dialog.addNumber("		Layer number? ",4);
	Dialog.addMessage("	Cell segmentation parameters: \n ");
	Dialog.addNumber("		Rolling background ",50);
	Dialog.addMessage("	CellWall selection parameters: \n ");
	Dialog.addNumber("		Enlargement factor ",1);
	Dialog.addNumber("		Band width in pixels",2);
	Dialog.addCheckbox("Shift Correction?", true);
	Dialog.show();
	
	Lnb = Dialog.getNumber();
	RB = Dialog.getNumber();
	Ero = Dialog.getNumber();
	band= Dialog.getNumber();
	shift=Dialog.getCheckbox();

///Creation du tableau de résultat
	title1 = "[Result summary:]"; 
	f=title1; 
	run("New... ", "name="+title1+" type=Table");
	print(f,"\\Headings: Image name \t Cell Layer\t Cell number \t Mean Mb fluorescence ");

		name= getTitle();
		
if (shift== true){
	JACoP_VanS(name);
	}
	
		selectWindow(name);
		
	run("Duplicate...", "duplicate");
	lenght=lengthOf(name);
	title=substring(name, 0, lenght-4 );
	rename ("temp");
	run("Split Channels");
	selectWindow("C1-temp");
	run("Duplicate...", "duplicate");	
	rename("mb");	    
	    
	    run("Set Scale...", "distance=0 known=0 pixel=1 unit=pixel global");
	
/// Segmentation  des cellules

setBatchMode(true);	
						    run("Subtract Background...", "rolling="+RB+"");
							run("Unsharp Mask...", "radius=5 mask=0.60");
							setAutoThreshold("Otsu dark");
							setOption("BlackBackground", true);
							run("Convert to Mask");
							run("Invert");
							run("Erode");
							//run("Fill Holes");
							run("Dilate");				
							run("Distance Transform Watershed", "distances=[Chessknight (5,7,11)] output=[16 bits] normalize dynamic=3 connectivity=8");			
							//run("Distance Transform Watershed", "distances=[Chessboard (1,1)] output=[16 bits] normalize dynamic=2 connectivity=8");

setBatchMode(false);
							run("Merge Channels...", "c1=C1-temp c2=mb-dist-watershed create");
							Stack.setChannel(2);
							run("Grays");
							close("mb");
							/// Selection cellule & Mesures
			Celllayer=newArray();
			Cellfluo=newArray();
			CellNumber=newArray(4);
			color=newArray("orange","blue","yellow","green");
							
	for (i = 0; i < Lnb; i++) {
		run("Select None");	
		Roibasal=roiManager("Count"); 
		Layer="Layer_"+(i+1);
		selectWindow("temp");
		Stack.setChannel(2);
		setTool("wand");
		waitForUser("Select Cells and add to manager "+Layer);
		totRois=roiManager("Count");
		CellNumber[i]= totRois-Roibasal;
		run("Clear Results");
		p=0;
		for (n = Roibasal; n <= totRois-1; n++) {
		Celllayer[n]=Layer;
		selectWindow("C2-temp");
		roiManager("select", n);
		run("Interpolate", "interval=1 smooth adjust");
		run("Enlarge...", "enlarge="+Ero);
		run("Make Band...", "band="+band);
		run("Measure");
		Cellfluo[n]=getResult("Mean", p);
		roiManager("Set Color",color[i]);
		run("Add Selection...");
		p++;
		}
							}
					for (m = 0; m < totRois; m++) {
						print(f, title+"\t"+ Celllayer[m] +"\t"+m+1+"\t"+Cellfluo[m]);			
					}
		roiManager("reset");
		run("To ROI Manager");
		run("Green");
		selectWindow("temp");
		Stack.setChannel(2);
		run("Delete Slice", "delete=channel");
		run("Merge Channels...", "c1=temp c2=C2-temp create");
		run("From ROI Manager");	
		
function JACoP_VanS(name){
setBatchMode(true);
selectWindow(name);
run("Make Composite");
rename(name);
for (i = 0; i < 2; i++) {
run("Split Channels");
run("JACoP ", "imga=C1-"+name+" imgb=C2-"+name+" ccf=20");
selectWindow("Van Steensel's CCF between C1-"+name+" and C2-"+name+"");
logContent=call("ij.IJ.getLog");
delay=parseInt(substring(logContent, lastIndexOf(logContent, "c =")+3, lastIndexOf(logContent, "c =")+11));
print(delay);
selectWindow("C1-"+name+"");
run("Translate...", "x="+delay+" y=0 interpolation=None");
run("Merge Channels...", "c1=C1-"+name+" c2=C2-"+name+" create");
run("Rotate 90 Degrees Right");
}
run("Rotate... ", "angle=-180 grid=1 interpolation=Bilinear");
setBatchMode(false);
}
