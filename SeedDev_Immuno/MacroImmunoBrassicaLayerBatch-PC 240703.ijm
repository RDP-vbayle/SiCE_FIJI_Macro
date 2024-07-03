///// Test macro for single image immuno quantification
///// INPUT Folder with .czi file with two channels C1 cacofluor, C2 siganl to quantify

	
	
	
	setOption("BlackBackground", true);
	roiManager("Reset");
	run("Clear Results");
	run("Remove Overlay");
	setOption("ExpandableArrays", true);
	run("Set Measurements...", "area mean centroid center fit shape stack redirect=None decimal=3");
	//run("Select None");
	
///Choix de répertoire

dir1 = getDirectory("Choose Directory ");
list1 = getFileList(dir1);
direct = File.getParent(dir1);
lDir=lengthOf(direct);

/// Selection paramètres
	Dialog.create("Immuno Macro");
	Dialog.addNumber("		Layer number? ",2);
	Dialog.addMessage("	Cell segmentation parameters: \n ");
	Dialog.addNumber("		Rolling background ",50);
	Dialog.addNumber("		UnsharpMask radius ",5);
	Dialog.addNumber("		Watershed Dynamic ",10);
	Dialog.addMessage("	CellWall selection parameters: \n ");
	Dialog.addNumber("		Dilate cell wall n",5);
	Dialog.addNumber("		Enlargement cell wall n+1 ",6);
	Dialog.addNumber("		Band width in pixels of segmented cell wall n+1",6);
	Dialog.addCheckbox("Layer?", true);
	Dialog.show();
	
	Lnb = Dialog.getNumber()+1;
	RB = Dialog.getNumber();
	UsRad = Dialog.getNumber();
	watDyn = Dialog.getNumber();
	dil = Dialog.getNumber();
	Ero = Dialog.getNumber();
	band= Dialog.getNumber();
	CplLayer=Dialog.getCheckbox();
	
	
///Creation du tableau de résultat
	title1 = "[Result summary:]"; 
	f=title1; 
	run("New... ", "name="+title1+" type=Table");
if (CplLayer== true){
	print(f,"\\Headings: Image name \t Seed Number \t Cell Layer\t Mean Mb fluorescence\t Cell area");
	}
else {
	print(f,"\\Headings: Image name \t Seed Number \t Cell Layer\t Cell number \t Mean Mb fluorescence\t Cell area");
}


for (m=0; m<list1.length; m++) {
		
			showProgress(m+1, list1.length);
			open(dir1+list1[m]);
					    
					name= getTitle();
	getDimensions(width, height, channels, slices, frames);
	run("Duplicate...", "duplicate");
	run("Make Composite");
	rename("Composite_"+name);
	selectWindow(name);
					
			selectWindow(name);
			
	run("Duplicate...", "duplicate");
		    lenght=lengthOf(name);
			title=substring(name, 0, lenght-4 );
			
	seedNb=1;		
	
	rename ("temp");
	run("Split Channels");
	selectWindow("C2-temp");
	rename("fluo");	
	selectWindow("C1-temp");
	run("Duplicate...", "duplicate");	
	rename("mb");	    		    
	run("Set Scale...", "distance=0 known=0 pixel=1 unit=pixel global");
		
			/// Segmentation  des cellules
					selectWindow("mb");
					run("Duplicate...", "title=Cells");
					
setBatchMode(true);	
		run("Subtract Background...", "rolling="+RB+"");
		run("Unsharp Mask...", "radius="+UsRad+" mask=0.60");
		setAutoThreshold("Otsu dark");
		setOption("BlackBackground", true);
		run("Convert to Mask");
		run("Invert");
		run("Erode");
		run("Dilate");				
		run("Distance Transform Watershed", "distances=[Chessknight (5,7,11)] output=[16 bits] normalize dynamic="+watDyn+" connectivity=8");			
		run("Merge Channels...", "c1=C1-temp c2=Cells-dist-watershed create");
		Stack.setChannel(2);
		run("Grays");
		run("Add Slice", "add=channel");
		close("mb");
		close("Cells");

setBatchMode(false);
										
/// Cell selection
				Celllayer=newArray();
				CellArea=newArray();
				Cellfluo=newArray();
				CellNumber=newArray();
				color=newArray("orange","blue","yellow","green","red");
	
				roiManager("Reset");	
				setTool("wand");					
				waitForUser("Select outside ovule_");
				roiManager("Add");
				mergeROIs (CellArea,0,0);
				roiManager("Select", 1);
				roiManager("Rename", "Layer_0");
				roiManager("Select", 0);
				roiManager("delete");	
				
				for (i = 0; i < Lnb-1; i++) {
					run("Select None");		
					CellNumber[i]=CellSelect (i);
					run("Clear Results");
					}
				close("segCell");
			setBatchMode(true);	
				
					for (i = 0; i < Lnb-1; i++) {
					run("Select None");	
					newImage("Outside", "8-bit black", width, height, 1);
					roiManager("Select", findRoisWithName("Layer_"+i));
					run("Fill", "slice");
					run("Select None");
					
					for (k = 0; k < dil; k++) {
					run("Dilate");	
					}		
					if (CplLayer== true)
					{
					newImage("Wall"+i, "8-bit black", width, height, 1);
					roiManager("Select", findRoisWithName("Layer_"+i+1));
					run("Enlarge...", "enlarge="+Ero);					
					run("Make Band...", "band="+band);
					run("Fill", "slice");
					imageCalculator("AND Create", "Outside","Wall"+i);
					rename("MeasureWall"+i);
					fuseROIs ( );
					selectWindow("fluo");	
					roiManager("Select", roiManager("Count")-1);
					roiManager("Rename", "MeasuredL"+i+1);
					roiManager("Measure");
					print(f, title+"\t"+ seedNb+"\t"+m+1+"\t"+"Wall"+i+1+"\t"+getResult("Mean", i));
					selectWindow("Composite_"+name);
					roiManager("Select", roiManager("Count")-1);
					roiManager("Set Color", color[i]);	
					run("Add Selection...");
					close("Wall"+i);
					close("MeasureWall"+i);
					}
					
					else {
					for (n = 1; n < (CellNumber[i]+1); n++) {
					selectWindow("Outside");	
					run("Duplicate...", "title=OutsideBis duplicate");
					newImage("Wall"+i, "8-bit black", width, height, 1);
					roiManager("Select", findRoisWithName("Layer_"+i)+n);
					roiManager("Rename", "Layer"+i+1+"-Cell"+n);		
					run("Enlarge...", "enlarge="+Ero);					
					run("Make Band...", "band="+band);
					run("Fill", "slice");
					imageCalculator("AND Create", "OutsideBis","Wall"+i);
					rename("MeasureWall"+i);
					fuseROIs ( );
					selectWindow("fluo");	
					roiManager("Select", roiManager("Count")-1);
					roiManager("Rename", "MeasuredL"+i+1+"- Cell_"+n);
					roiManager("Measure");
					print(f, title+"\t"+ seedNb+"\t"+m+1+"\t"+"Wall"+i+1+"\t"+ n +"\t"+getResult("Mean", n-1));
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
						
			selectWindow("Composite_"+name);
			run("Stack to RGB");
			//saveAs("TIFF", dir1+"_"+background+"_"+stage+"-"+(m+1)+"_analysed");
			saveAs("TIFF", dir1+"_"+title+"_analysed");

			close("mb");
			close("fluo");
			run("Close All");
			roiManager("Reset");
			run("Clear Results");
			run("Remove Overlay");
			close("mb");
			close("fluo");
			
			}

function CellSelect (i)
{
		Roibasal=roiManager("Count"); 
		Layer="Layer_"+(i+1);
		selectWindow("temp");
		Stack.setChannel(2);
		
		selectWindow("temp");
			Stack.setChannel(2);
			run("Tile");
			setTool("wand");
			waitForUser("Select Cells and add to manager "+Layer);

		totRois=roiManager("Count");
		CellNb= totRois-Roibasal;
		for (v = 0; v < CellNb; v++) {
		mergeROIs (CellArea,Roibasal,nResults);
		}
		roiManager("Select", Array.slice(Array.getSequence(totRois), Roibasal));
		roiManager("Combine");
		run("Create Mask");
		run("Dilate");
		run("Dilate");
		run("Dilate");
		run("Dilate");
		run("Erode");
		run("Erode");
		run("Erode");
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


function mergeROIs (CellArea,ROInumber,RESULTnumber) {
	selectWindow("temp");
	Stack.setChannel(3);
	roiManager("select", ROInumber);
	run("Draw", "slice");
	run("Fill", "slice");
	roiManager("measure");
	CellArea[ROInumber]=getResult("Area", RESULTnumber);
	run("Select None");
	doWand(getResult("X", RESULTnumber), getResult("Y", RESULTnumber));
	roiManager("add");
	selectWindow("Results");
	Table.deleteRows(RESULTnumber, RESULTnumber);
	run("Clear", "slice");
	run("Select None");
	roiManager("select", ROInumber);
	roiManager("delete");
	}

function fuseROIs ( ){
	currentROIs=roiManager("count");
	run("Analyze Particles...", "add");
	measROIs=roiManager("count");
	roiManager("Select", Array.slice(Array.getSequence(measROIs), currentROIs));
	roiManager("Combine");
	roiManager("add");
	roiManager("Select", Array.slice(Array.getSequence(measROIs), currentROIs));
	roiManager("delete");
	
}
