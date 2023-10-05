dir1 = getDirectory("Choose Source Directory ");
list = getFileList(dir1);
// Stack processing
setBatchMode(true);
		
		for (i=0; i<list.length; i++) {
		showProgress(i+1, list.length);
		dir3=dir1+"Pool"+File.separator;
		File.makeDirectory(dir3);
		if (endsWith(list[i], ".tif")){
			subname=substring(list[i], 0, list[i].length-4);
			dir2=dir1+subname+File.separator;
			File.makeDirectory(dir2);
			File.rename(dir1+list[i], dir2+list[i]);
			File.copy(dir1+subname+"-spots.csv", dir3+subname+"-spots.csv");
			File.rename(dir1+subname+".xml", dir2+subname+".xml");
			File.rename(dir1+subname+"-spots.csv", dir2+subname+"-spots.csv");
		}
		}
