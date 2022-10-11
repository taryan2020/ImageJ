// This macro creates an average image stack from multiple image stacks for experiments performed in replicate. 
// The image stacks must be saved as a FITS file and named such that replicate stacks are the same but with an extension (eg. name, name_1, ...).

setOption("ExpandableArrays", true); // Allows arrays to be expanded iteratively.
path = File.openDialog("Select 1st file in series"); // Use dialog box to return the file name.
name = File.nameWithoutExtension; // Name is above without the extension.
dir = File.getParent(path); // dir is the name path name of folder containing the files to average.
list = getFileList(dir); // Returns all the files listed in the selected folder.
pathnames = newArray(); // Initialize an array for names without the file extension.
imagenames = newArray(); // Initialize an array for names with the file extension.
pathnames[0] = path; // Add the selected file to the array pathnames.
imagenames[0] = name+".fits"; // Add the selected file with the file extension to the array imagenames.
n = 0; // n is the number of files to similarly named to be averaged together.

// For all files within the selected folder, compare to the string of the selected file. If a file contains that string, it is saved to the arrays pathnames and imagenames:
for (i=0; i<list.length; i++) { // Loop over all files within the folder.
	in = indexOf(list[i],".fits"); // Checks if the file has extension ".fits".
	if (in != -1) { // If the file has the extension ".fits":
		comparename = substring(list[i],0,in); // comparename is the the file without the extension.
		if (startsWith(comparename, name) == 1) { // The beginning of the file name of the current file must exactly match the file name selected by the user.
			if (comparename != name) { // The current file name must not be the same as the user-selected file name.
					n++; // Incremenet +1 the total file number count.
					pathnames[n] = dir+File.separator+list[i]; // Add the current file name to pathnames.
					imagenames[n] = comparename+".fits"; // Add the current file name with the ".fits" extension to imagenames.
			}
		} 
	}
}

// Open the first 2 images, add them together, rename the resulting image "Sum Image," and close the original image files.
open(pathnames[0]);
open(pathnames[1]);
imageCalculator("Add create stack", imagenames[0], imagenames[1]);
rename("Sum Image");
close(imagenames[0]);
close(imagenames[1]);

// For remaining images in the list, iteratively open and add each to the "Sum Image," so that the resulting "Sum Image" is the arithmetic sum of all stacks:
m = n+1;
for (i=2; i<m; i++) {
	open(pathnames[i]);
	imageCalculator("Add create stack", imagenames[i], "Sum Image");
	close(imagenames[i]);
	close("Sum Image");
	rename("Sum Image");
}

// Divide the final summed stack by the total number of stacks to yield the average stack:
str = "value="+m+" stack";
run("Divide...", str);

rename(name+"_avg"); // Rename the stack as name_avg.
run("Fire"); // Display with "Fire" look-up table.
run("Enhance Contrast", "saturated=0.35"); // Enhance the contrast for visualization.

// Save the averaged image stack to the selected folder:
savename = dir+File.separator+name+"_avg.fits";
saveAs("Tiff",savename);