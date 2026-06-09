	setOption("BlackBackground", true);
	roiManager("Reset");
	run("Clear Results");
	run("Remove Overlay");
	setOption("ExpandableArrays", true);
	run("Set Measurements...", "area mean centroid center fit shape stack redirect=None decimal=3");

///Parameters

	dir1= getDir("input Directory");	

	list1 = getFileList(dir1);
	thresh = "RenyiEntropy" //or "Internodes","IJ_IsoData","RenyiEntropy", "IJ_IsoData"
	
/////Result table	
	g = "[Coloc summary:]";
	run("New... ", "name="+g+" type=Table");
	print(g,"\\Headings: Image name \t Pearson Coef \t NB obj in A \t NB obj in B X \t Touching obj in A \t Touching obj in B");
	
	for (m=0; m<list1.length; m++) {
		roiManager("Reset");
		run("Clear Results");
		run("Remove Overlay");
		showProgress(m+1, list1.length);
		if(endsWith(list1[m], "DoG.tif") ){
		open(dir1+list1[m]);	
		title=getTitle();
		name= substring(title, 0, lastIndexOf(title, "DoG.tif"));
		rename ("image");
		run("Z Project...", "projection=[Sum Slices]");
		rename("SUM");
		run("Split Channels");
		run("JACoP ", "imga=C1-SUM imgb=C2-SUM pearson");
			logContent=call("ij.IJ.getLog");
			Pears=substring(logContent, lastIndexOf(logContent, "r=")+2, lastIndexOf(logContent, "\n"));
			
		selectImage("C1-SUM");
		setAutoThreshold(thresh+" dark no-reset");
		run("Convert to Mask");
		selectImage("C2-SUM");
		setAutoThreshold(thresh+" dark no-reset");
		run("Convert to Mask");
		
		run("DiAna_Segment", "img=C1-SUM filter=none rad=1.0 thr=1-5-2000-false-false");
		run("DiAna_Segment", "img=C2-SUM filter=none rad=1.0 thr=1-5-2000-false-false");
		
		close("C1-image");
		close("C2-image");
		run("DiAna_Analyse", "img1=C1-SUM img2=C2-SUM lab1=C1-SUM-labelled lab2=C2-SUM-labelled coloc");
		
			logContent=call("ij.IJ.getLog");
			nbA=substring(logContent, lastIndexOf(logContent, "number of objects in image A =")+30, lastIndexOf(logContent, "number of objects in image B =")-1);
			nbB=substring(logContent, lastIndexOf(logContent, "number of objects in image B =")+30, lastIndexOf(logContent, "number of touching objects in image A =")-1);
			nbTinA=substring(logContent, lastIndexOf(logContent, "number of touching objects in image A =")+39, lastIndexOf(logContent, "number of touching objects in image B =")-1);
			nbTinB=substring(logContent, lastIndexOf(logContent, "number of touching objects in image B =")+39, lastIndexOf(logContent, "\n"));	
				
		IJ.renameResults("ColocResults","Results");
		selectWindow("Results");
		saveAs("Results", dir1+""+name+"_DiAna");
		print(g,name+"\t"+Pears+"\t"+nbA+"\t"+nbB+"\t"+nbTinA+"\t"+nbTinB);
		close("*");
		}	
		}
