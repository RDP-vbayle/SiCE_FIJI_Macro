// Shift correction macro
// INPUT imported stack from Spiro acquisitions

title=getTitle();
//setBatchMode(true);
setOption("ExpandableArrays", true);
getDimensions(width, height, channels, slices, frames);

///Kymograph to visualise shifts in acquisition

	makeLine(400, 210, 2994, 210);
	run("Multi Kymograph", "linewidth=1");
	makeRectangle(0, 0, 300, slices);
	run("Crop");
	shift=newArray();
	shiftBis=newArray();
	n=0;
	getDimensions(width, height, channels, slices, frames);
	
	makeRectangle(0, 0, 300, 2);
	run("Duplicate...", " ");
	run("Median...", "radius=4");
	run("Find Edges");
	run("Find Maxima...", "prominence=50 output=[Point Selection]");
	getSelectionCoordinates(xpoints, ypoints);
	close("Kymograph-1");
	print(xpoints[0]);

	
///Detect shifts and store Frame nb in shift array

	for (i = 0; i < height; i++) {
		if (getPixel(0, i)>100) {
			ratio=getPixel(0, i)/getPixel(xpoints[0]-5, i);
			limit=1.2;
		}
		else {
			ratio=getPixel(xpoints[0]+20, i)/getPixel(0, i);	
			limit=2;
		}
print(i+"-"+ratio);
		if (ratio>limit) {
		shift[n]=i;
		n++;
		}
		}		
		
/// Calculate in pixel the translation to correct the shift

for (j = 0; j < shift.length; j++) {
	makeRectangle(0, shift[j], width, 1);
	run("Duplicate...", " ");
	run("Median...", "radius=4");
	run("Find Edges");
	run("Find Maxima...", "prominence=300 output=[Point Selection]");
	getSelectionCoordinates(Xpoints, Ypoints);
	selectWindow("Kymograph");
print(Xpoints[0]);
	if (getPixel(0, shift[j])>50) {
	shiftBis[j]=xpoints[0]-Xpoints[0];
	}
	else {
	shiftBis[j]=shiftBis[j-1]; ///shift is not calculated in the dark images
	}	
	close("Kymograph-1");
	}
Array.print(shift);	
Array.print(shiftBis);
Array.getStatistics(shiftBis, min, max, mean, stdDev) 
	Shift=max;
print(Shift);
selectWindow(title);
close("\\Others");

/// Apply "Shift" translation to shift array (frames)

for (i = 0; i < shift.length; i++) {
	setSlice(shift[i]+1);
	run("Translate...", "x="+Shift+10+" y=0 interpolation=None slice");
}
run("Rotate 90 Degrees Right");
