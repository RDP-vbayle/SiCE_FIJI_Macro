	setOption("BlackBackground", true);
	roiManager("Reset");
	run("Clear Results");
	run("Remove Overlay");
	setOption("ExpandableArrays", true);
	run("Set Measurements...", "area mean centroid center fit shape stack feret's redirect=None decimal=3");
	run("Select None");

/// Selection paramètres

	Dialog.create("Immuno Macro");
	Dialog.addMessage("	Cell segmentation parameters: \n ");
	Dialog.addNumber("		Rolling background ",10);
	Dialog.addNumber("		Wavelet plane ",2);
	Dialog.addMessage("	CellWall selection parameters: \n ");
	Dialog.addNumber("		Dilate",2);
	Dialog.addNumber("		Shrink factor",-1);
	Dialog.addNumber("		Band",4);
	Dialog.addCheckbox("Layer?", false);
	Dialog.addCheckbox("Shift Correction?", true);
	Dialog.show();
	
	method = Dialog.getChoice();
	
	RB = Dialog.getNumber();
	wave = Dialog.getNumber();
	dil = Dialog.getNumber();
	Ero = Dialog.getNumber();
	band= Dialog.getNumber();
	CplLayer=Dialog.getCheckbox();
	shift=Dialog.getCheckbox();

///Creation du tableau de résultat
	title1 = "[Result summary:]"; 
	f=title1; 
	run("New... ", "name="+title1+" type=Table");
if (CplLayer== true){
	print(f,"\\Headings: Image name \t Cell Layer\t Mean Mb fluorescence ");
	}
else {
	print(f,"\\Headings: Image name \t Cell Layer\t Cell number \t Mean Mb fluorescence ");
}


		name= getTitle();
		
if (shift== true){
	JACoP_VanS(name);
	}
	
run("Duplicate...", "duplicate");
		run("Make Composite");
		rename("Composite_"+name);
		selectWindow(name);
		
run("Duplicate...", "duplicate");
	    lenght=lengthOf(name);
		title=substring(name, 0, lenght-4 );
	    run("Stack to Images");
		selectWindow(title+"-1-0001");
        rename("blue");
        selectWindow(title+"-1-0002");
        rename("green");
	    run("Set Scale...", "distance=0 known=0 pixel=1 unit=pixel global");
	
/// Segmentation  des cellules
		selectWindow("blue");
		run("Duplicate...", "title=Cells");
		
setBatchMode(true);	
						    run("Subtract Background...", "rolling="+RB+"");
							run("Select All");
							roiManager("Add");
							run("Wavelet A Trou");
							run("8-bit");
							selectWindow("Wavelet");						
							setSlice(wave);
							run("Duplicate...", "duplicate range="+wave+"-"+wave+"");
							rename("mb");
							close("Wavelet");
					
							selectWindow("mb");
						
							setAutoThreshold("Triangle dark no-reset");

							run("Convert to Mask");
							run("Invert");
							run("Make Binary");
							run("Distance Map");			
							run("Find Maxima...", "noise=10  exclude output=[Single Points]");
							run("Analyze Particles...", "  show=[Count Masks] clear");
							rename("seedCount");
							run("Marker-controlled Watershed", "input=Cells marker=seedCount mask=None calculate use");
							rename("segCell");
							close("seedCount");
							close("mb Maxima");
							close("mb");							
							close("cells");
							setBatchMode(false);
							
							/// Selection cellule & Mesures

			CellNumber=newArray(4);
		                    roiManager("Reset");	
		                    setTool("wand");					
							waitForUser("Select outside ovule_");
							run("Measure");
							feretX= getResult("FeretX", 0);
							feretY= getResult("FeretY", 0);
							run("Clear Results");
							if (feretX!=0 && feretY!=0){
							run("Make Inverse");
							}
							roiManager("Add");
							roiManager("Select", 0);
							roiManager("Rename", "Layer_0");
							
					for (i = 0; i < 4; i++) {
							run("Select None");		
							CellNumber[i]=CellSelect(i);
							run("Clear Results");
							}
	close("segCell");
setBatchMode(true);	
	
		for (i = 0; i < 4; i++) {
		run("Clear Results");
		run("Select None");	
		newImage("Outside", "8-bit black", 1936, 1460, 1);
		roiManager("Select", findRoisWithName("Layer_"+i));
		run("Fill", "slice");
		run("Select None");
		
		for (k = 0; k < dil; k++) {
		run("Dilate");	
		}

		if (CplLayer== true)
		{
		newImage("Wall"+i, "8-bit black", 1936, 1460, 1);
		roiManager("Select", findRoisWithName("Layer_"+i+1));		
		run("Enlarge...", "enlarge="+Ero);					
		run("Make Band...", "band="+band);
		run("Fill", "slice");
		imageCalculator("AND Create", "Outside","Wall"+i);
		rename("MeasureWall"+i);
		run("Analyze Particles...", "add");
		selectWindow("green");	
		roiManager("Select", roiManager("Count")-1);
		roiManager("Rename", "MeasureL"+i+1);
		roiManager("Measure");
		print(f, title+"\t"+"Mur"+i+1+"\t"+getResult("Mean", 0));
		selectWindow("Composite_"+name);
		roiManager("Select", roiManager("Count")-1);
		ColoredOverlay(i); 

		close("Wall"+i);
		close("MeasureWall"+i);
		}
		else {
		for (n = 1; n < (CellNumber[i]+1); n++) {
		selectWindow("Outside");	
		run("Duplicate...", "title=OutsideBis duplicate");
		newImage("Wall"+i, "8-bit black", 1936, 1460, 1);
		roiManager("Select", findRoisWithName("Layer_"+i)+n);
		roiManager("Rename", "Layer"+i+1+"-Cellule"+n);		
		run("Enlarge...", "enlarge="+Ero);					
		run("Make Band...", "band="+band);
		run("Fill", "slice");
		imageCalculator("AND Create", "OutsideBis","Wall"+i);
		rename("MeasureWall"+i);
		run("Analyze Particles...", "add");
		selectWindow("green");	
		roiManager("Select", roiManager("Count")-1);
		roiManager("Rename", "MeasureL"+i+1+"- Cell_"+n);
		roiManager("Measure");
		print(f, title+"\t"+"Mur"+i+1+"\t"+ n +"\t"+getResult("Mean", n-1));
		selectWindow("Composite_"+name);
		roiManager("Select", roiManager("Count")-1);
		ColoredOverlay(i); 
		close("Wall"+i);
		close("MeasureWall"+i);			
		}	
		close("Outside");
			}
		}

		
setBatchMode(false);
			
selectWindow(name);
run("Make Composite");
roiManager("Select", findRoisWithName("MeasureL1"));
roiManager("Set Color", "orange");
run("Add Selection...");							
roiManager("Select", findRoisWithName("MeasureL2"));;
roiManager("Set Color", "blue");
run("Add Selection...");
roiManager("Select", findRoisWithName("MeasureL3"));
roiManager("Set Color", "yellow");
run("Add Selection...");
roiManager("Select", findRoisWithName("MeasureL4"));
roiManager("Set Color", "green");
run("Add Selection...");

close("blue");
close("green");

function CellSelect (i)
{
		Roibasal=roiManager("Count"); 
		Layer="Layer_"+(i+1);
		selectWindow("blue");
		setTool("wand");
		selectWindow("segCell");
		waitForUser("Select Cells and add to manager "+Layer);
		totRois=roiManager("Count");
		CellNb= totRois-Roibasal;
		roiManager("Select", Array.slice(Array.getSequence(totRois), Roibasal));
		roiManager("Combine");
		run("Create Mask");
		run("Dilate");
		run("Erode");
		run("Analyze Particles...", "add");
		close("Mask");
		roiManager("Select", totRois);
		roiManager("Rename", Layer);
		//run("Make Band...", "band=3");
		roiManager("Update");
		return (CellNb);
		}

function findRoisWithName(roiName) { 
	nR = roiManager("Count");
	RoiIdx = NaN; 
	for (i=0; i<nR; i++) { 
		roiManager("Select", i); 
		rName = Roi.getName(); 
		if (matches(rName, roiName) ) { 
			RoiIdx = i; 
		}		 
	} 
	return RoiIdx;
	}

function ColoredOverlay(i) {
	if (i==0){
	roiManager("Set Color", "orange");
	run("Add Selection...");
		}
	if (i==1){							
	roiManager("Set Color", "blue");
	run("Add Selection...");
	}
	if (i==2){
	roiManager("Set Color", "yellow");
	run("Add Selection...");
	}
	if (i==3){
	roiManager("Set Color", "green");
	run("Add Selection...");
	}
	}


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
