// This macro performs background subtraction of ROIs from a Results table with user-drawn background ROIs from an image time series.
// ROIs are linked to a background ROI by drawing freehand shapes over a cluster of ROIs that alternate with the freehand background ROIs.

run("Set Measurements...", "mean redirect=None decimal=3"); // Set measurements to mean only and the number of decimal points in results table to 3.
setOption("ExpandableArrays", true); // Enable arrays to be iteratively expanded.

// User selects the range of contiguous ROIs in ROI Manager for background subtraction:
waitForUser("Select beginning ROI.");
start = roiManager("index");
waitForUser("Select ending ROI.");
end = roiManager("index");

// leftover is an array to ensure all ROIs have corresponding background ROIs to make sure each is background subtracted.
leftover=newArray(end-start);
for (i=0; i<(end-start+1); i++) {
	leftover[i] = start+i;
}

ROIroi = newArray(0); // An array containing the freehand ROIs encompassing ROIs for subtraction that make up the Results Table.
BGroi = newArray(0); // An array for the freehand background ROIs.

// Freehand ROIs and background ROIs are alternating at the end of the user-specificed range of ROIs to background subtract:
c = roiManager("count")-end-1;
n = c/2;
for (i=0; i<n; i++) {
	ROIroi[i] = end+1+(2*i);
	BGroi[i] = end+2+(2*i);
}

// This loop checks each synaptic ROI to make sure its included an a freehand ROI for background subtraction:
while (leftover.length > 0) {
	for (i=0; i<ROIroi.length; i++) { // Goes through list of freehand ROIs to select cluster of synaptic ROIs:
		for (r=start; r<end+1; r++) { // Goes through synaptic ROIs:
			roiManager("select",r);
			Roi.getCoordinates(x,y); // Gets xy coordinates defining synaptic ROI:
			roiManager("select",ROIroi[i]);
			for (j=0; j<x.length; j++) {
				if (selectionContains(x[j],y[j]) == 1) { // Checks if the freehand ROI contains an xy coordinate of the synaptic ROI:
					for (l=0; l<leftover.length; l++) {
						if (leftover[l] == r) {	
							leftover = Array.deleteValue(leftover,r); // Deletes the index from the leftover array.
						}
					}
				}	
			}
		}
	}
	// If not all synaptic ROIs are contained within freehand ROIs for background subtraction, the 
	if (leftover.length > 0) {
		print("These ROIs are not included for background subtracted:");
		for (i=0; i<leftover.length; i++) {
			roiManager("select",leftover[i]);
			print(Roi.getName);
		}
		roiManager("select",leftover);
		waitForUser("Adjust to ensure all ROIs are background subtracted.")
		ROIroi = newArray(0);
		BGroi = newArray(0);
		
		c = roiManager("count")-end-1;
		n = c/2;
		for (i=0; i<n; i++) {
			ROIroi[i] = end+1+(2*i);
			BGroi[i] = end+2+(2*i);
		}
	}
	for (i=0; i<(end-start+1); i++) {
		leftover[i] = start+i;
	}
}

// leftover array is re-initialized to make sure each synaptic ROI is background-subtracted only once:
leftover=newArray(end-start); 
for (i=0; i<(end-start+1); i++) {
	leftover[i] = start+i;
}

BGname = newArray(n);
BGroiSort = Array.sort(BGroi);
for (j=0; j<n; j++) {
	for (jj=0; jj<n; jj++) {
		if (BGroi[j] == BGroiSort[jj]) {
			BGname[j] = "Mean"+toString(jj+1);
			jj = n;
		}
	}
}

// Measure mean fluorescence for background ROIs and save to table "Background":
BGTableName = "Background";
roiManager("select", BGroi);
roiManager("multi-measure one");
Table.rename("Results", BGTableName);

waitForUser("Load a single results table to background subtract."); // CSV file containing synaptic ROI traces before background subtraction is loaded into ImageJ by user.
ROItableName = Table.title;

// Make new name using name of table loaded by user:
in = indexOf(ROItableName, ".csv");
NewTableName = substring(ROItableName,0,in)+" Background Subtracted";

// Rename headings of the synaptic ROI table to enable background subtraction based on background results table:
headings = split(Table.headings);
if (substring(headings[0],0,4) == "Mean") {
	for (i=0; i<headings.length; i++) {
		roiManager("select",leftover[i])
		Table.renameColumn(headings[i], Roi.getName); 
	}
}
else if (substring(headings[1],0,4) == "Mean") {
	for (i=1; i<headings.length; i++) {
		roiManager("select",leftover[i])
		Table.renameColumn(headings[i], Roi.getName); 
	}
}
Table.rename(ROItableName, NewTableName);

for (i=0; i<ROIroi.length; i++) {
	// For each synaptic ROI, determine which freehand ROI it falls within:
	for (r=start; r<end+1; r++) {
		roiManager("select",r);
		rName = Roi.getName;
		Roi.getCoordinates(x,y);
		roiManager("select",ROIroi[i]);
		for (j=0; j<x.length; j++) {
			if (selectionContains(x[j],y[j]) == 1) {
				for (l=0; l<leftover.length; l++) {
					if (leftover[l] == r) {	
						// Perform subtraction from Background table column of synaptic ROI results table:
						selectWindow(BGTableName);
						BGCol = Table.getColumn(BGname[i]);
						selectWindow(NewTableName);
						OldCol = Table.getColumn(rName);
						NewCol = newArray(OldCol.length);
						for (k=0; k<OldCol.length; k++) {
							NewCol[k] = OldCol[k]-BGCol[k];
						}
						Table.setColumn(rName, NewCol);
						leftover = Array.deleteValue(leftover,r); // Delete the synaptic ROI index from leftover array to prevent background subtraction being performed more than once.
					}
				}
			}	
		}
	}
}

close("Background");