/// Reset
	setOption("BlackBackground", true);
	roiManager("Reset");
	run("Clear Results");
	run("Remove Overlay");
	setOption("ExpandableArrays", true);
	run("Set Measurements...", "area mean centroid center fit shape stack redirect=None decimal=3");
	run("Select None");
	run("Overlay Options...", "stroke=red width=0 fill=none set");
	getPixelSize(unit, pixelWidth, pixelHeight);
	//dim=unit;
	run("Set Scale...", "distance=0 known=0 unit=pixel");
	
/// Result table 
	title1 = "[Rayons de courbure et angles]"; 
	f=title1; 
	run("New... ", "name="+title1+" type=Table");
	print(f,"\\Headings: N \t Angle \t Radius \t Concavity \t Distance covered "+ unit);
	
/// Parameters

	Dialog.create("Select Parameters");
	Dialog.addNumber("Segment length: ", 20, 1,4, " pixels");
	Dialog.addNumber("Angle limit",5, 1,3, "Degres");
	Dialog.show();
	limit = Dialog.getNumber();
	anglelimit = Dialog.getNumber();

/// Seed countour
	setTool("freeline");
	waitForUser("Draw seed contour");
	run("Add Selection...");
	run("Fit Spline");
	getSelectionCoordinates(xpoints, ypoints);
	run("Measure");
	SeedLength= getResult("Length", 0);
	run("Clear Results");
	
	run("Overlay Options...", "stroke=blue width=0 fill=none set");	

nb_points=xpoints.length;
nbmeasure=0;
x=0;

	do {
	run("Clear Results");
		i=1;
		do{
			
	// Recherche du premier points distance (x,X1)>limit
		makeLine(xpoints[x] , ypoints[x],  xpoints[x+i], ypoints[x+i]);
		run("Measure");		
		distance = getResult("Length", 0);
		i=i+1;
		run("Clear Results");
		} while (distance<limit);	
		X1=x+i-1;
		
	// Recherche du deuxième points Distance(X1,X2)>limit
		i=1;
		do{	
		makeLine(xpoints[X1] , ypoints[X1],  xpoints[X1+i], ypoints[X1+i]);
		run("Measure");		
		distance = getResult("Length", 0);
		i=i+1;
		run("Clear Results");
		} while (distance<limit);	
		X2=X1+i-1;
		
	// Angle measurement
		makeSelection("angle",newArray(xpoints[x],xpoints[X1], xpoints[X2]),newArray(ypoints[x],ypoints[X1],ypoints[X2]));
		run("Add Selection...");
		run("Measure");
		Angle=getResult("Angle", 0);
		run("Clear Results");
		if ((180-anglelimit)<Angle && Angle<(180+anglelimit)) { // Condition dans le cas où les points sont colinéaires.
			CurvR = "line";
			CurvOrient="Colinear";	
		}
		else {
		
	// Radius measurement
		roiManager("Reset");
		makeSelection("angle",newArray(xpoints[x],xpoints[X1], xpoints[X2]),newArray(ypoints[x],ypoints[X1],ypoints[X2]));
		run("Fit Circle");
		run("Measure");
		Ym= getResult("YM", 0);
		
	// Shape based on fit circle
		if (ypoints[X1]>Ym){
			CurvOrient="Convex";}
		else {
			CurvOrient="Concave";}		
		run("Clear Results");
		roiManager("Add");	
		pix= "µm";
		CurvR=CurvAnalysis(pix);
	}
	print(f, x+ "\t" + Angle + "\t" + CurvR+ "\t" + CurvOrient+ "\t" + (2*nbmeasure*limit*pixelWidth));
	x=X2;
	nbmeasure=nbmeasure+1;
	} while ((2*nbmeasure*limit)<(SeedLength-5*limit)) 
	
run("Set Scale...", "distance="+1/pixelWidth+" known=1 unit="+unit);

// Tracer 3 points avec polyline.
// Puis Fit Circle et mesure du rayon (major/2) qui correspond au rayon de courbure.
// Problème: lorsque le cercle résultant ne rentre pas dans l'image, la mesure du rayon est fausse,
// donc il faut s'assurer qu'il rentre, ce qui est mesuré par "Circ." (pour Circularity).
// Création d'une image vide d'une certaine taille puis la macro met le cercle au centre.
// La boucle while permet d'augmenter au fur et à mesure la taille de l'image jusqu'à ce que
// le cercle rentre.

function CurvAnalysis(pix) {
			run("Measure");
			Rnd=getResult("Round", 0);
			i=1;
			if(Rnd==1)
			{
			CurvAng=getResult("Major", 0)/2;
			}
			else
			{
			do {
			run("Clear Results");
			roiManager("Centered", "true");
			newImage("Untitled", "8-bit black", 512*i, 512*i, 1);
			roiManager("Select", 0);
			run("Measure");
			Rnd=getResult("Round", 0);
			selectWindow("Untitled");
			run("Close");
			i=i+1;
			CurvAng=getResult("Major", 0)/2;
			Curv=1/CurvAng; 
			   } while (Rnd<0.98);
			CurvAng=getResult("Major", 0)/2;
			   } 
			return CurvAng; 
			}


