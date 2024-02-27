// Shift correction macro
// INPUT imported stack from Spiro acquisitions
dbg=false;
Range=7;
Var=100;
n=0;

title=getTitle();

setBatchMode(true);

if (dbg==true) {
setBatchMode(false);	
}

setOption("ExpandableArrays", true);
getDimensions(width, height, channels, slices, frames);

///Kymograph to visualise shifts in acquisition

	makeLine(300, 210, 2994, 210);
	run("Multi Kymograph", "linewidth=1");
	makeRectangle(0, 0, 300, slices);
	run("Crop");
	shift=newArray();
	shiftBis=newArray();
	getDimensions(width, height, channels, slices, frames);
	
	findBoundaries(0,0,width,1,Var);
	getSelectionCoordinates(xpoints, ypoints);
	close("Kymograph-1");
	DayBound=xpoints[0];
	findBoundaries(0,0,3,height,10);
	getSelectionCoordinates(xpoints, ypoints);
	Array.getStatistics(ypoints, min, max, mean, stdDev);
	close("Kymograph-1");
if (dbg==true) {
run("Select None");
makePoint(0,min);
waitForUser("Y dark");
}
		ypoint=min;
	if (getPixel(0, min)>100) {
		ypoint=min+1;
	}
	findBoundaries(0,ypoint,width,1, Var);
	getSelectionCoordinates(xpoints, ypoints);
	Array.getStatistics(xpoints, min, max, mean, stdDev);
	close("Kymograph-1");
	NightBound=min;
if (dbg==true) {
run("Select None");
makePoint(min,ypoint);
waitForUser("X dark");
}
	
print(DayBound+"-"+NightBound+"-"+ypoint);
	
///Detect shifts and store Frame nb in shift array

	for (i = 0; i < height; i++) {
		if (getPixel(0, i)>100) {
	findBoundaries(0,i,width,1,Var);
	getSelectionCoordinates(xpoints, ypoints);
	Array.getStatistics(xpoints, min, max, mean, stdDev);
if (dbg==true) {	
run("Select None");
makePoint(min, i);
waitForUser(i);
}
	close("Kymograph-1");
	CurBound=min;
	Diff=DayBound-CurBound;
		}
		else {
	findBoundaries(0,i,width,1,Var);
	getSelectionCoordinates(xpoints, ypoints);
	Array.getStatistics(xpoints, min, max, mean, stdDev);
	close("Kymograph-1");
if (dbg==true) {	
run("Select None");
makePoint(min, i);
waitForUser(i);
}
	CurBound=min;
	Diff=NightBound-CurBound;
		}
print(i+"-"+CurBound);
print(i+"-"+Diff);
		if (abs(Diff)>Range){	
		shift[n]=i;
		if (Diff<0) {
		shiftBis[n]=Diff-10;	
		}
		else {
		shiftBis[n]=Diff+10;	
		}
		n++;
		}
		}		
		
Array.print(shift);	
Array.print(shiftBis);

selectWindow(title);
close("\\Others");

/// Apply "Shift" translation to shift array (frames)

for (i = 0; i < shift.length; i++) {
	setSlice(shift[i]+1);
	run("Translate...", "x="+shiftBis[i]+" y=0 interpolation=None slice");
	}

run("Rotate 90 Degrees Right");

function findBoundaries(X0, Y0, X,Y,Var) { 
	makeRectangle(X0, Y0, X, Y);
	run("Duplicate...", " ");
	run("Enhance Contrast...", "saturated=5 normalize");
	run("Variance...", "radius="+Var+"");
	run("8-bit");
	run("Find Maxima...", "prominence=100 output=[Point Selection]");
}

