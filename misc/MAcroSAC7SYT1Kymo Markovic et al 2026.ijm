///// Test macro 
///// INPUT multichannel time lapses image
	
	setOption("BlackBackground", true);
	roiManager("Reset");
	run("Clear Results");
	run("Remove Overlay");
	setOption("ExpandableArrays", true);
	run("Set Measurements...", "area mean centroid center fit shape stack redirect=None decimal=3");
	//run("Select None");
	
	/// Selection paramètres
	Dialog.create("ERCS Kymo Macro");
	Dialog.addDirectory("Input Directory", getDirectory("imagej") );
	Dialog.addMessage("	Cell segmentation parameters: \n ");
	Dialog.addNumber("		Rolling background ",200);
	Dialog.addNumber("		Median radius ",5);
	Dialog.addNumber("		DoG MinSigma ",0.5);
	Dialog.addNumber("		DoG MinSigma ",3);
	Dialog.addNumber("		ERcs MinSize ", 0.07);
	Dialog.addChoice("Threshold method", newArray("RenyiEntropy","IJ_IsoData","Intermodes"));
	Dialog.addMessage("	kymograph parameters: \n ");
		Dialog.addNumber("		Channel for kymo",2);
	Dialog.addNumber("		Kymolength (pixels)",30);
	Dialog.addNumber("		KymoWidth ",3);
	Dialog.addString("Channel2: ", "SYT1");
	Dialog.addString("Channel1: ", "SAC7");
	Dialog.show();
	
	dir1=Dialog.getString();
	RB = Dialog.getNumber();
	Rad = Dialog.getNumber();
	DoGmin=Dialog.getNumber();
	DoGmax=Dialog.getNumber();
	ERcsMin=Dialog.getNumber();
	thresh = Dialog.getChoice();
	Kchan = Dialog.getNumber();
	Klen = Dialog.getNumber();
	Kwid = Dialog.getNumber();
	Channel2= Dialog.getString();
	Channel1= Dialog.getString();

	list1 = getFileList(dir1);
	
	saveDir = dir1 + File.separator +"Output"+ File.separator ;
	File.makeDirectory(saveDir);
		
for (m=0; m<list1.length; m++) {
		
		showProgress(m+1, list1.length);
		if(endsWith(list1[m], ".nd")|endsWith(list1[m], ".czi") ){
		open(dir1+list1[m]);
//Get Infos from the file
		title=getTitle();
		name= substring(title, 0, lastIndexOf(title, "_w"));
		getDimensions(width, height, channels, slices, frames);
		getPixelSize(unit, pixelWidth, pixelHeight);
		
		rename("Temp");
		Stack.setChannel(Kchan);
		resetMinAndMax;
		setTool("rectangle");
		waitForUser("Crop around bulge");
		isROI=selectionType();
		if (isROI==-1) {
	close();		
	}
	else {
//		roiManager("add");
//		roiManager("Select", 0);
//		roiManager("rename", "Initial Crop");
		run("Crop");
setBatchMode(true);		
		// background removal
		Stack.setChannel(1);
		resetMinAndMax;
		run("Subtract Background...", "rolling="+RB+""); 	
		Stack.setChannel(2);
		run("Subtract Background...", "rolling="+RB+""); 
		Stack.setChannel(Kchan);
		DoG(DoGmin,DoGmax); 
		setAutoThreshold(thresh+" dark no-reset");
		run("Convert to Mask");
		run("Analyze Particles...", "size="+ERcsMin+"-Infinity display clear include summarize add");
		nbERCS= roiManager("count");
		close("ERcsmin");
//		run("F4DR Estimate Drift", "time=10 max=0 reference=[previous frame (better for live)] apply choose=["+dir1+"]");				
//		File.delete(dir1+"DriftTable.njt");
//		close("Temp");
		rename("Temp");
		run("Split Channels");
		selectWindow("C1-Temp");
		resetMinAndMax;
		DoGStacks(DoGmin,DoGmax);
		rename(Channel1+"DoG");
		selectWindow("C2-Temp");
		DoGStacks(DoGmin,DoGmax);	
		rename(Channel2+"DoG");

		for (i = 0; i < nbERCS; i++) {
			setSlice(1);
			selectWindow(Channel1+"DoG");
			makeLine(getResult("X", i)/pixelWidth, (getResult("Y", i)/pixelWidth)-Klen/2, getResult("X", i)/pixelWidth, (getResult("Y", i)/pixelWidth)+Klen/2);
			run("Multi Kymograph", "linewidth="+Kwid);
			rename(i+1);
			print(i);
			if (i==0) {
 			rename("Combined"+Channel1);
			}
			if (i>=1) {
					run("Combine...", "stack1=Combined"+Channel1+" stack2="+(i+1));	
					rename("Combined"+Channel1);
			}
		}
		for (i = 0; i < nbERCS; i++) {
			setSlice(1);
			selectWindow(Channel2+"DoG");
			makeLine(getResult("X", i)/pixelWidth, (getResult("Y", i)/pixelWidth)-Klen/2, getResult("X", i)/pixelWidth, (getResult("Y", i)/pixelWidth)+Klen/2);
			run("Multi Kymograph", "linewidth="+Kwid);
			rename(i+1);
			print(i);
			if (i==0) {
 			rename("Combined"+Channel2);
			}
			if (i>=1) {
					run("Combine...", "stack1=Combined"+Channel2+" stack2="+(i+1));	
					rename("Combined"+Channel2);
			}
		}
	run("Merge Channels...", "c2=SYT1DoG c6=SAC7DoG create keep");
	saveAs("TIFF", saveDir+name+"_DoG");
	run("Merge Channels...", "c2=CombinedSYT1 c6=CombinedSAC7 create keep");
	saveAs("TIFF", saveDir+name+"_Composite");
	selectWindow("CombinedSAC7");
	saveAs("TIFF", saveDir+name+"_SAC7");
	selectWindow("CombinedSYT1");
	saveAs("TIFF", saveDir+name+"_SYT1");
	setBatchMode(false);
	close("*");
}
}}
	
	
function DoG(DoGmin,DoGmax) { 
// function description
	// difference of gaussian
		run("Duplicate...", "title=ERcsmin");
		run("Duplicate...", "title=ERcsmax");
		selectWindow("ERcsmin");
		run("Gaussian Blur...", "sigma="+DoGmin);
		selectWindow("ERcsmax");
		run("Gaussian Blur...", "sigma="+DoGmax);
		imageCalculator("Subtract", "ERcsmin","ERcsmax");
		// difference of gaussian
		close("ERcsmax");
		}
		
function DoGStacks(DoGmin,DoGmax) { 
// function description
	// difference of gaussian
	run("Duplicate...", "duplicate");
	rename("ERcsmin");
	run("Duplicate...", "duplicate");
	rename("ERcsmax");
		selectWindow("ERcsmin");
		run("Gaussian Blur...", "sigma="+DoGmin+" stack");
		selectWindow("ERcsmax");
		run("Gaussian Blur...", "sigma="+DoGmax+" stack");
		imageCalculator("Subtract stack","ERcsmin","ERcsmax");
		// difference of gaussian
		close("ERcsmax");
		}