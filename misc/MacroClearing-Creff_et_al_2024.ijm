//// Macro for Cleared Arabidopsis Seed size semi automatic measuremesnt. INPUT: Folder containing brightfield images
//// Distance Transform Watershed plugin needed https://imagej.net/plugins/distance-transform-watershed
/// Reset
    setOption("BlackBackground", true);
    roiManager("Reset");
    run("Clear Results");
    run("Remove Overlay");
    setOption("ExpandableArrays", true);
    run("Set Measurements...", "area mean centroid center fit shape stack redirect=None decimal=3");
    run("Select None");
    run("Line Width...", "line=4");

/// Segmentation options

    Dialog.create("Segmentation:");
    Dialog.addCheckbox("Automatic Segmentation for Later stages", true);
    Dialog.addCheckbox("Automatic Lines", true);
    Dialog.show();
    Seg=Dialog.getCheckbox();
    lines=Dialog.getCheckbox();

///Directory selection
dir1 = getDirectory("Choose Directory ");
list1 = getFileList(dir1);
direct = File.getParent(dir1);

///Result table

    title1 = "[Clearing Result summary:]";
    f=title1;
    run("New... ", "name="+title1+" type=Table");

    print(f,"\\Headings: Image name \t Background \t Embryo shape \t Area \t Lenght \t Width ");

/// Images opening & loop

for (m=0; m<list1.length; m++) {

                showProgress(m+1, list1.length);
                open(dir1+list1[m]);

            /// Extraction info nom image

                name= getTitle();
                background=substring(name,0,indexOf(name,"-"));


/// Stage Selection

                Dialog.create("Embryo shape selection:");
                Dialog.addChoice(" ", newArray("Bent","Torpedo","Heart","Mis-oriented", "Compact","Delayed","Aborted", "Undetermined"));
                Dialog.addMessage("select ROIs (Area/Length/Width) and press space each time \n ");
                Dialog.show();
                stage = Dialog.getChoice();

/// Measures
                if(Seg==false)
                {
                    setTool("polygon");
                while (!isKeyDown("space")) {
                    }
                    run("Fit Spline");
                    roiManager("add");
                    run("Select None");
                }
                else {
                    automatSeg(name);
                while (!isKeyDown("space")) {
                    }
				St= selectionType();                
                if(St==-1)
                {
                setTool("polygon");
                selectWindow(name);
				waitForUser("Draw seed manually and press OK");
//		while (!isKeyDown("enter")) {
//                    }
                    run("Fit Spline");
                    roiManager("add");
                    run("Select None");
                }    
                 else {
   
                    roiManager("add");
                    run("Select None");
                    close("contour");
                }}
                
                
/// Major and minor axis measurements
                
        if (lines==false) {

                setTool("line");
            while (!isKeyDown("space")) {
                }
                roiManager("add");
                run("Select None");
            while (!isKeyDown("space")) {
                }
                  roiManager("add");
                  run("Select None");
                roiManager("Measure");
                print(f, name+"\t"+ background +"\t"+stage+"\t"+getResult("Area", 0)+"\t"+getResult("Length", 1)+"\t"+getResult("Length", 2));
                }
        else {
            roiManager("select", 0);
            run("Measure");
            print(f, name+"\t"+ background +"\t"+stage+"\t"+getResult("Area", 0)+"\t"+getResult("Major", 0)+"\t"+getResult("Minor", 0));
        }
                run("Close All");
                roiManager("Reset");
                run("Clear Results");
            }


function automatSeg(name)
{
    run("Stack to RGB");
    rename("temp");
    run("8-bit");
    run("Variance...", "radius=5");
    run("Duplicate...", "title=contour");
    setAutoThreshold("Huang dark");
    run("Convert to Mask");

    run("Dilate");
    run("Dilate");
    run("Fill Holes");
    run("Erode");
    run("Erode");
    run("Distance Transform Watershed", "distances=[Chessknight (5,7,11)] output=[16 bits] normalize dynamic=10 connectivity=4");
    setTool("wand");
    }


