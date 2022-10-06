// This macro uses the Find Maxima plug-in to identify puncta and places ROIs after user adjustment. 
// ROIs are placed such that the first is closest to the upper left corner and subsequent ROIs are placed to minimize distance with the prior ROI placed.

run("Set Scale...", "distance=0 known=0 unit=pixel"); // Set units of image to pixels to ensure accurate ROI placement in the image.

ROI_diameter = 5; // Set the diameter of circular ROIs.
r = ROI_diameter/2; // Convert ROI diameter to radius.

// Set a variable "offset" to center circular ROIs on point selections:
if (ROI_diameter%2 > 0) {
	offset = ROI_diameter/2-0.5;
}
else {
	offset = ROI_diameter/2;
}

waitForUser("Select image"); // Click to select the image to use for ROI placement.
getDimensions(width, height, channels, slices, frames); // Get the dimensions of the image.

// Run the ImageJ plugin "Find Maxima" and turn on "Preview point selection". Iteratively set the "Prominence" until it captures the nerve terminals while minimizing selection of non-synaptic regions, such as autofluorescence:
run("Find Maxima..."); 

waitForUser("Adjust points"); // Manually add or remove points that may be erroneously identified or missed.

getSelectionCoordinates(xpoints, ypoints); // Add the coordinates of the ROIs to arrays.
ROInum = xpoints.length; // ROInum is the number of ROIs.
distances = newArray(ROInum); // Initialize an array for the distances of the ROI to the upper left corner, point (0,0).
// Initialize arrays to store ROI coordinates that have been ordered by shortest distance between sequential ROIs:
xpoints_arranged = newArray(ROInum); 
ypoints_arranged = newArray(ROInum);

for (i=0; i<ROInum; i++) {
	distances[i] = Math.sqrt(xpoints[i]^2+ypoints[i]^2); // For each ROI, find the distance to the point (0,0):
}
Array.sort(distances, xpoints, ypoints); // Sort the coordinates of the ROIs by increasing distance to point (0,0):
// Set the coordinates of the first ROI in the arranged arrays:
xpoints_arranged[0] = xpoints[0]; 
ypoints_arranged[0] = ypoints[0];
// Delete the coordinates just added to the arranged arrays so that remaining ROIs can be ordered by distance from the initially placed ROI:
xpoints = Array.deleteIndex(xpoints,0);
ypoints = Array.deleteIndex(ypoints,0);

// Calculate distances between the previously placed ROI and all remaining ROIs, sort the ROI coordinates by distances, add the coordinates of the ROI with minimum distance to the arranged arrays, and delete the ROI coordinates
// from the original arrays of ROI coordinates:
for (i=1; i<ROInum; i++) {
	distances = newArray(xpoints.length); // Initialize a new array for the distances of ROIs to the previously placed ROI.
	for (j=0; j<xpoints.length; j++) {
		distances[j] = Math.sqrt(Math.sqr(xpoints[j]-xpoints_arranged[i-1]) + Math.sqr(ypoints[j]-ypoints_arranged[i-1])); // Calculate the distance of ROIs to the previously placed ROI.
	}
	Array.sort(distances, xpoints, ypoints); // Sort the coordinates of ROIs by increasing distances from the previously placed ROI.
	// Add the coordinates from the closest ROI to the arranged arrays:
	xpoints_arranged[i] = xpoints[0];
	ypoints_arranged[i] = ypoints[0];
	// Delete the coordinates just added to the arranged arrays so that remaining ROIs can be ordered by distance from the ROI most recently placed:
	xpoints = Array.deleteIndex(xpoints,0);
	ypoints = Array.deleteIndex(ypoints,0);
}

// Place circular ROIs at coordinates from arranged arrays:
for (i=0; i<ROInum; i++) {
	makeOval(xpoints_arranged[i]-offset, ypoints_arranged[i]-offset, ROI_diameter, ROI_diameter);
	roiManager("add");
	// Select the added ROI and rename it:
	roiManager("select",roiManager("count")-1);
	if ((i+1) < 10) {
		roiManager("rename",'ROI00'+(i+1));
	}
	else if ((i+1) < 100) {
		roiManager("rename",'ROI0'+(i+1));
	}
	else {
		roiManager("rename",'ROI'+(i+1));
	}
}

// Adjust ROI placement to center the ROIs on the center of mass within the ROI:
for (i=0; i<roiManager("count"); i++) {
	roiManager("select", i);
	x = getValue("XM")-r;
	y = getValue("YM")-r;
	Roi.move(x,y);
	roiManager("Update");
}// Delete the point just added to the arranged arrays so that remaining ROIs can be ordered by distance from the initially placed ROI:// Delete the point just added to the arranged arrays so that remaining ROIs can be ordered by distance from the initially placed ROI: