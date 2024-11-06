///Macro to apply process to folders and subfolders (adapted from Rob Lees)
/// Vincent Bayle 220524 SiCEteam


var outputDir
var inputdir

// Directories selection
input= getDirectory(" Source Directory ?");
main=input
output = getDirectory("Main Destination Directory ?");
temp=output

inputdir= input;
outputDir=output;

setBatchMode(true);

processFolder(input);
processFolderBis(output);
	
function processFolder(input) {
	list = getFileList(input);
	list= Array.sort(list);
	for (j = 0; j < list.length; j++) {
		
// identify subfolders		
		if(File.isDirectory(input + list[j])){
			tempInputDir = input + list[j];
			tempInputDir =substring(tempInputDir,0,lengthOf(tempInputDir)-1)+File.separator;
			tempInputDir=replace(tempInputDir, File.separator, "/");
			inputdir=replace(inputdir, File.separator, "/");
			outputDir=replace(outputDir, File.separator, "/");
    		saveDir = replace(tempInputDir, inputdir, outputDir); 
    		File.makeDirectory(saveDir);
			processFolder("" + input + list[j]);
			}
// retreive image files
		if(endsWith(list[j], ".tif")||endsWith(list[j], ".czi")){
			processFile(input, output, list[j]);
			}
}
}

function processFolderBis(output) {
	list = getFileList(output);
	list= Array.sort(list);
	for (j = 0; j < list.length; j++) {
		
// identify subfolders		
		if(File.isDirectory(output + list[j])){
			processFolderBis("" + output + list[j]);
			}
// retreive image files
		if(endsWith(list[j], ".tif")||endsWith(list[j], ".czi")){
			normaliZ(output,input, list[j]);
			}
}
}
function processFile(input, output, file) {
	open(input+File.separator+file);
	run("Z Project...", "projection=[Sum Slices]");
	input=replace(input, File.separator, "/");
	saveDir = replace(input, inputdir, outputDir); 
	File.makeDirectory(saveDir);
	print(saveDir);
	saveAs("TIFF", saveDir+file+"_Stack");
	run("Close All");
}

function normaliZ(output,input, file) {
	list1 = getFileList(output);
	MaxCh1= newArray();
	MinCh1= newArray();
	MaxCh2= newArray();
	MinCh2= newArray();
/// Loop beginning


for (i = 0; i < list1.length; i++) {
		open(output+list1[i]);
		setSlice(1);
		getMinAndMax(min, max);
		MaxCh1[i]= max;
		makeRectangle(0, 0, 20, 20);
 		run("Measure");
 		MinCh1[i]= getResult("Mean", 0);
 		setSlice(2);
 		run("Select None");
		getMinAndMax(min, max);
		MaxCh2[i]= max;
		makeRectangle(0, 0, 20, 20);
 		run("Measure");
 		MinCh2[i]= getResult("Mean", 1);
 		close();
 		run("Clear Results");
}

Array.getStatistics(MaxCh1, min, max, mean, stdDev);
newMaxCh1=max;
Array.getStatistics(MaxCh2, min, max, mean, stdDev);
newMaxCh2=max;
Array.getStatistics(MinCh1, min, max, mean, stdDev);
newMinCh1=min; //min = minimal background, replace by max or mean
Array.getStatistics(MinCh2, min, max, mean, stdDev);
newMinCh2=min;

for (i = 0; i < list1.length; i++) {
		open(output+list[i]);
		title=getTitle();
		name= substring(title, 0, title.length-14);
		run("8-bit");
		setSlice(2);
		run("Delete Slice", "delete=channel");
		setSlice(1);
		setMinAndMax(newMinCh1, newMaxCh1);
		setOption("ScaleConversions", true);
		run("Apply LUT");
		run("Fire");
		saveAs("TIFF", output+name+"_Norm");
		close("*");		
}
}
