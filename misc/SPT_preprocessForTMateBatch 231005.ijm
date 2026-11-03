///// ImageJ Macro to remove scale and save in .tif. 

// Directories selection 

dir1 = getDirectory("Choose Source Directory ");
dir2=dir1+"Native"+File.separator;
dir3=dir1+"Treated"+File.separator;
File.makeDirectory(dir2);
File.makeDirectory(dir3);

list = getFileList(dir1);

// Stack processing
setBatchMode(true);

		for (i=0; i<list.length; i++) {
		showProgress(i+1, list.length);
		open(dir1+list[i]);
		title=getTitle();
		lenght=lengthOf(title);
		newName=substring(title, 0, lastIndexOf(title,".") );
		run("Set Scale...", "distance=0 known=0 unit=pixel");
		saveAs("TIFF", dir3+newName);
		File.rename(dir1+list[i], dir2+list[i]);
		close();
		}

