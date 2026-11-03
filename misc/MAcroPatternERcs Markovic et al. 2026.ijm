///////Macro for Contact site quantification in WT vs sac7 in Thricho and Atrichoblast cells. INPUT: Ilastik segmented

	setOption("BlackBackground", true);
	roiManager("Reset");
	run("Clear Results");
	run("Remove Overlay");
	setOption("ExpandableArrays", true);
	run("Set Measurements...", "area mean centroid center fit shape stack redirect=None decimal=3");

///Creation du tableau de résultat
	title1 = "[Result segmentation:]"; 
	f=title1; 
	run("New... ", "name="+title1+" type=Table");
	print(f,"\\Headings: Image name \t ROI number \t Cell Type \t Cell Area \t Nb contact site \t Contact sites % Area \t Average CS size");
	title2 = "[Contact size:]"; 
	g=title2; 
	run("New... ", "name="+title2+" type=Table");
	print(g,"\\Headings: Image name \t ROI number \t Cell Type \t Contact site nb \t Contact site size \t Contact site Circ.");
	
dir1 = getDirectory("Choose Source Directory ");
list = getFileList(dir1);
i=1;

for (file=0; file<list.length; file++) {
	    showProgress(file+1, list.length);
	    
	if(endsWith(list[file], ".TIF")){
	    open(dir1+list[file]);

	    getPixelSize(unit, pixelWidth, pixelHeight);
	    title=getTitle();
	    title=substring(title, 0, title.length-4);
	    index=findSegmented(list,title);
		open(dir1+list[index]);
		rename("segmented");
		run("Enhance Contrast", "saturated=0.35");
		run("Set Scale...", "distance="+1/pixelWidth+" known=1 unit="+unit+"");
		ThreshSegmented();
/// Cellfile type & ROI selection
		setTool("polygon");
		run("Tile");	
		waitForUser("Draw ROI");
	isROI=selectionType();
	if (isROI==-1) {
	close();		
	}
	else {
		roiManager("add");
		run("Measure");
		CellArea= getResult("Area", 0);
		Dialog.create("Cell type selection:");
		Dialog.addChoice(" ", newArray("Early Mer","Mer","Elong","Dif","Bulge"));
		Dialog.show();				
		CellType = Dialog.getChoice();		
		selectWindow("CS");
		roiManager("select", 0);	
		run("Analyze Particles...", "size=5-Infinity pixel display clear include summarize");	
		selectWindow("Summary");
		lines = split(getInfo(), "\n");
		headings = split(lines[0], "\t");
		values = split(lines[1], "\t");
		nbDots= parseFloat(values[1]);
		CSarea= parseFloat(values[2]);
		AVsize= parseFloat(values[3]);
		pctCS= parseFloat(values[4]);
		run("Close"); 
		
		print(f, title+"\t"+ i+"\t"+CellType+"\t"+CellArea+"\t"+nbDots+"\t"+pctCS+"\t"+AVsize);	
		
/// particle measurement

			for(l=0; l<=nbDots-1; l++)
				{
		print(g, title+"\t"+ i+"\t"+CellType+"\t"+l+1+"\t"+getResult("Area",l)+"\t"+getResult("Circ.",l));
			}	
	roiManager("Reset");
	run("Clear Results");
	Dialog.create("Another ROI?");
	Dialog.addCheckbox("OK?", true);
	Dialog.show();
	newROI=Dialog.getCheckbox();
	if (newROI==true)
			{
		file=file-1;
		i=i+1;
			}
	else {	
		i=1;
	}
	
	}
	
	close("*");
	}
	}
			
function findSegmented(list,title) {
	for (k=0; k<list.length; k++) {
	if(startsWith(list[k], title+"_Simple Segmentation.tif")){
	index=k;
	}
	}
return index;
}

function ThreshSegmented() { 
	selectWindow("segmented");
	run("8-bit");
//	run("Invert");
	setAutoThreshold("Default dark no-reset");
	setOption("BlackBackground", true);
	run("Convert to Mask");
	rename("CS");
}

function prefiltering(imagenb) { 
	for (i = 0; i < imagenb; i++) {
isROI=selectionType();
if (isROI==-1) {
close();		
}
else {
run("Add Selection...");
run("Save");
close();
}
}
}
// function description

