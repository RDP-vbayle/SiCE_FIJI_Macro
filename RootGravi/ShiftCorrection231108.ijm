// Shift correction macro
// INPUT imported stack from Spiro acquisitions

title=getTitle();
setBatchMode(true);
setOption("ExpandableArrays", true);
getDimensions(width, height, channels, slices, frames);

///Kymograph to visualise shifts in acquisition

	makeLine(300, 210, 2994, 210);
	run("Multi Kymograph", "linewidth=1");
	makeRectangle(0, 0, 300, slices);
	run("Crop");
	shift=newArray();
	shiftBis=newArray();
	n=0;
	getDimensions(width, height, channels, slices, frames);
	
	findBoundaries(0,0,width,1);
	getSelectionCoordinates(xpoints, ypoints);
	close("Kymograph-1");
	DayBound=xpoints[0];
	findBoundaries(0,0,3,height);
	getSelectionCoordinates(xpoints, ypoints);
	Array.getStatistics(ypoints, min, max, mean, stdDev);
	close("Kymograph-1");
//run("Select None");
//makePoint(0,min);
//waitForUser("dark");
		ypoint=min;
	if (getPixel(0, min)>100) {
		ypoint=min+1;
	}
	findBoundaries(0,ypoint,width,1);
	getSelectionCoordinates(xpoints, ypoints);
	Array.getStatistics(xpoints, min, max, mean, stdDev);
	close("Kymograph-1");
//run("Select None");
//makePoint(min,ypoint);
//waitForUser("dark");
	NightBound=min;
	Range=7;
print(DayBound+"-"+NightBound+"-"+ypoint);
	
///Detect shifts and store Frame nb in shift array

	for (i = 0; i < height; i++) {
		if (getPixel(0, i)>100) {
	findBoundaries(0,i,width,1);
	getSelectionCoordinates(xpoints, ypoints);
	Array.getStatistics(xpoints, min, max, mean, stdDev);
	close("Kymograph-1");
//run("Select None");
//makePoint(min, i);
//waitForUser(i);
	CurBound=min;
	Diff=DayBound-CurBound;
		}
		else {
	findBoundaries(0,i,width,1);
	getSelectionCoordinates(xpoints, ypoints);
	Array.getStatistics(xpoints, min, max, mean, stdDev);
	close("Kymograph-1");
//run("Select None");
//makePoint(min, i);
//waitForUser(i);
	CurBound=min;
	Diff=NightBound-CurBound;
		}
print(i+"-"+CurBound);
print(i+"-"+Diff);
		if (abs(Diff)>Range){	
		shift[n]=i;
		shiftBis[n]=Diff;
		n++;
		}
		}		
		
Array.print(shift);	
Array.print(shiftBis);
Array.getStatistics(shiftBis, min, max, mean, stdDev);
if (mean>0) {
	Shift=max+10;
}
else {
	Shift=min-10;
}

print(Shift);
selectWindow(title);
close("\\Others");

/// Apply "Shift" translation to shift array (frames)

for (i = 0; i < shift.length; i++) {
	setSlice(shift[i]+1);
	run("Translate...", "x="+Shift+" y=0 interpolation=None slice");
	}


run("Rotate 90 Degrees Right");

function findBoundaries(X0, Y0, X,Y) { 
	makeRectangle(X0, Y0, X, Y);
	run("Duplicate...", " ");
	run("Enhance Contrast...", "saturated=5 normalize");
	run("Variance...", "radius=5");
	run("8-bit");
	run("Find Maxima...", "prominence=50 output=[Point Selection]");
}

