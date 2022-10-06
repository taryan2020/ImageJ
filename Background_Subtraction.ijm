// The macro performs background subtraction from individual ROIs using the nearest neighbor from background ROIs.
// The ROIs corresponding to synapses must be listed before the background ROIs in ROI manager.
// The macro prompts the user to select the last synaptic ROI in the ROI manager.
// Fluorescence traces from matched background ROIs generate a kymograph that is subtracted from the kymograph of synaptic ROIs.

run("Set Measurements...", "mean redirect=None decimal=3"); // Sets the output of the Results table to only measurement of the mean of ROIs listed to the accuracy of 3 decimal places.
setOption("ExpandableArrays", true); // Allows arrays in the macro to be initialized as empty, allowing values to be sequentially added.
name = getTitle(); // Set the name of the open image file to "name".

ROItot = roiManager("count"); // ROItot is the sum of synaptic and background ROIs.
waitForUser("Select ending ROI."); // User clicks on the last synaptic ROI in the ROI manager.
end = roiManager("index"); // "end" is the position in the ROI manager of the user-selected last ROI in the list of synaptic ROIs.
ROIs = Array.getSequence(end+1); // Create an array "ROIs" with the list of integers up to the position of the last synaptic ROI in the ROI manager.
// Create arrays for the coordinates of synaptic and background ROIs.
ROIcoordX = newArray(0);
ROIcoordY = newArray(0);
BGcoordX = newArray(0);
BGcoordY = newArray(0);

BGs = newArray(0); // Create an array of integers corresponding to the ROI manager positions.
BGmatched = newArray(0); // Create an array that will be assigned the index position of the background ROI matched to a synaptic ROI.
BGadded = newArray(0); // Create an integer array with the positions of the ROI manager corresponding to the matched background ROIs added to the ROI manager for the purpose of background subtraction.

// Store the x and y coordinates for eaech synaptic ROI into the corresponding arrays.
for (i=0; i<end+1; i++) {
	roiManager("select",i);
	// Store the x and y coordinates of the centroid for each backgroud ROI into the corresponding arrays:
	ROIcoordX[i] = getValue("X");
	ROIcoordY[i] = getValue("Y");
}

for (i=0; i<(roiManager("count")-end-1); i++) {
	BGs[i] = end+1+i; // Assign ROI manager positions to the array "BGs" for each background ROI.
	roiManager("select",end+1+i);
	// Store the x and y coordinates of the centroid for each backgroud ROI into the corresponding arrays:
	BGcoordX[i] = getValue("X");
	BGcoordY[i] = getValue("Y");
}

// Create an array containing the index values of background ROIs matched to synaptic ROIs and added to the ROI manager:
for (i=0; i<end+1; i++) {
	BGadded[i] = ROIs[i] + ROItot;
}

// Matches each synaptic ROI to a background ROI by minimum distance between respective centroids:
for (i=0; i<end+1; i++) {
	xDis = ROIcoordX[i] - BGcoordX[0];
	yDis = ROIcoordY[i] - BGcoordY[0];
	dismin = sqrt((xDis*xDis)+(yDis)*(yDis)); // Calculate the distance between a synaptic ROI and the first background ROI as "dismin", which will be sequentially reset to the minimum distance.
	BGmatched[i] = end+1; // Set the index of the matched background ROI to the first background ROI listed.
	for (j=1; j<BGcoordX.length; j++) {  
		xDis = ROIcoordX[i] - BGcoordX[j];
		yDis = ROIcoordY[i] - BGcoordY[j];
		distance = sqrt((xDis*xDis)+(yDis)*(yDis)); // Calculate the distance between the synaptic ROI and all subsequent background ROIs.
		// If the distance is less than the prior minimum distance to a background ROI, update the match index to the current background ROI index and reset the "dismin" to the new minimum value:
		if (distance < dismin) {
			BGmatched[i] = BGs[j];
			dismin = distance;
		}
	}
}

// Select matched background ROIs and add them to the ROI manager in order:
for (i=0; i<BGmatched.length; i++) {
	roiManager("select", BGmatched[i]);
	roiManager("add");
}

// Measure the fluorescence from all synaptic ROIs:
roiManager("select", ROIs);
roiManager("multi-measure one");
Table.rename("Results", "ROIs"); // Save the fluorescence values to a table renamed "ROIs":

// Measure the fluorescence from all matched background ROIs:
roiManager("deselect");
roiManager("select", BGadded);
roiManager("multi-measure one");

// Delete the matched background ROIs that were added to the end of the ROI manager:
roiManager("select", BGadded);
roiManager("delete");

run("Results to Image"); // Convert the background fluorescence traces table into a kymograph.
rename("BG"); // Rename the background traces kymograph "BG".

Table.rename("ROIs", "Results"); // Rename the synaptic ROIs table to "Results" to convert to a kymograph.
run("Results to Image"); // Convert the synaptic fluorescence traces table into a kymograph.
rename("ROIs"); // Rename the synaptic traces kymograph "ROIs".

imageCalculator("Subtract create", "ROIs","BG"); // Subtract the background fluorescence traces from the synaptic traces by performing image subtraction on the respective kymographs.
close("ROIs"); // Close the synaptic traces kymograph.
close("BG"); // Close the background traces kymograph.
close("Results"); // Close the Results table.

// This section calculates the mean across all ROIs and plots it:
getDimensions(width, height, channels, slices, frames); // Get the image dimensions of the kymograph.
meanarray = newArray(height); // Initialize array for mean values.
// Calculate mean for each timepoint by measuring the mean of a line drawn across the kymograph, and save the value to meanarray.
for (y=0; y<height; y++) {
	makeLine(0,y,width,y);
	getStatistics(area, mean, min, max, std, histogram);
	meanarray[y] = mean;
}
Array.show("ROI Mean", meanarray); // Show mean values in a table.
Plot.create("Mean Trace", "X", "Y", meanarray); // Plot the mean values.

run("Image to Results"); // Convert the kymograph of background-subtracted synaptic traces into a Results table.