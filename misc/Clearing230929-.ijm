/// Reset
	setOption("BlackBackground", true);
	roiManager("Reset");
	run("Clear Results");
	run("Remove Overlay");
	setOption("ExpandableArrays", true);
	run("Set Measurements...", "area mean centroid center fit shape stack redirect=None decimal=3");
	run("Select None");
	run("Overlay Options...", "stroke=none width=0 fill=none");
	RoiManager.associateROIsWithSlices(false);
	RoiManager.restoreCentered(false);
	RoiManager.useNamesAsLabels(false);
	
///Directories selection

dir1 = getDirectory("Choose Input Directory ");
list1 = getFileList(dir1);
direct = File.getParent(dir1);
dir2 = getDirectory("Choose Output Directory ")
FileNb = parseInt(substring(list1[list1.length-1], indexOf(list1[list1.length-1], "Seed")+4, lastIndexOf(list1[list1.length-1], "-")));

///Result table creation

	title1 = "[Clearing Result summary:]"; 
	f=title1; 
	run("New... ", "name="+title1+" type=Table");

	print(f,"\\Headings: Image name \t Background \t Embryo shape \t Area \t Albumen size \t Nuclei nb ");

/// Loop beginning

for (m=1; m<FileNb+1; m++) {
					
				showProgress(m+1, FileNb);
				File.openSequence(dir1, " filter=Seed"+m+"-");
			
/// Extraction information from image name
			
				name= substring(list1[list1.length-1],0, indexOf(list1[list1.length-1], "Seed")+4)+m;
				background=substring(name,0,indexOf(name,"-Seed"));
			
/// Seed & Albumen ROI selection
			
					setTool("polygon");
				do {
				waitForUser("Draw Seed contour");
				IsROI=selectionType();	
				} while (IsROI ==-1);
					run("Fit Spline");
					roiManager("add");
					roiManager("select", 0);
					roiManager("rename", "Seed");
					run("Select None");
					roiManager("Show None");
				do {
				waitForUser("Draw Albumen contour");
				IsROI=selectionType();	
				} while (IsROI ==-1);
				
					run("Fit Spline");
					roiManager("add");
					roiManager("select", 1);
					roiManager("rename", "Albumen");
					run("Select None");
					roiManager("Show All");
/// Stage selection
			
				Dialog.create("Embryo shape selection:");
				Dialog.addChoice(" ", newArray("Bent","Torpedo","Heart","Mis-oriented", "Compact","Delayed","Brown", "Undetermined"));
				Dialog.show();				
				stage = Dialog.getChoice();		
	
// Quantification	of Areas	
			
			roiManager("multi-measure");
			AreaSeed=getResult("Area", 0);
			AreaAlb=getResult("Area", 1);
			run("Clear Results");
			
			rename(name);	
			run("Select None");
			setTool("Multipoint");
			run("Point Tool...", "type=Dot color=Red size=Medium label counter=0");
			waitForUser("Add Nuclei to ROI manager (for each slice)");		
			run("Measure");
			TotNuc= nResults;
			slicenb= newArray();
		
//// Z-Projection

		for (i = 0; i < TotNuc; i++) {
			slicenb[i]=getResult("Slice", i);
		}
		Array.getStatistics(slicenb, min, max, mean, stdDev);
		run("Duplicate...", "duplicate range="+min+"-"+max+"use");
		run("Z Project...", "projection=Median");
		
////Overlay flatten and output saving
		
		roiManager("select", 0);	
		roiManager("Set Color", "Red");
		run("Add Selection...");
		
		roiManager("select", 1);
		roiManager("Set Color", "green");
		run("Add Selection...");
		roiManager("delete");
		
		for (j= 2; j <roiManager("count"); j++) {
		roiManager("select", j);
		roiManager("Set Color", "yellow");
		run("Add Selection...");
		}
		run("Flatten");	
		saveAs("TIFF", dir2+name+" Analysed");	
		Overlay.clear;
		
/// Fill result table

				print(f, name+"\t"+ background +"\t"+stage+"\t"+AreaSeed+"\t"+AreaAlb+"\t"+TotNuc);
				run("Close All");
				roiManager("Reset");
				run("Clear Results");
			}


function automatSeg( name)
{
	run("8-bit");
	run("Morphological Filters", "operation=[Black Top Hat] element=Disk radius=50");
	setAutoThreshold("Huang dark");
	setOption("BlackBackground", true);
	run("Convert to Mask");
	run("Fill Holes");
	run("Erode");
	run("Erode");
	run("Erode");
	run("Erode");
	run("Dilate");
	run("Dilate");
	setTool("wand");
	}
