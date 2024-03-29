

function result = Tester(path,Layer)
%Tester functions much like trainer1 except for out input data, also
%produces a prediction
FeatureList=[];
addpath('images')
addpath(path)
truthfile = imread('mine.tif');
imagefile = tif_to_matrix('image.tif');
% Load our tiff stack of training images to be processed
ImSynapse = im2bw(truthfile);
ImOrig = imagefile(:,:,Layer);

%get centroids
cc = bwconncomp(ImSynapse);
tcent = regionprops(cc,'centroid');
tcentroids = round(cat(1, tcent.Centroid));
%%%%%%%%%%%%%%%%%%%%%%%%%%
%place 70x70 window around
%%%%%%%%%%%%%%%%%%%%%%%%%%
winsize = 70;
Locations = tcentroids;
Locationsrange = zeros(size(Locations,1),2);

%Determine the starting point for windows
for i = 1:size(Locations,1)
if Locations(i,1)-winsize/2 <=0
Locationsrange(i,1) = 1;
elseif Locations(i,1)+winsize/2 >=1024
Locationsrange(i,1) = 1024-winsize;
else Locationsrange(i,1) = Locations(i,1)-winsize/2;
end
if Locations(i,2)-winsize/2 <=0
Locationsrange(i,2) = 1;
elseif Locations(i,2)+winsize/2 >=1024
Locationsrange(i,2) = 1024-winsize;
else Locationsrange(i,2) = Locations(i,2)-winsize/2;
end
end

%Add some contrast
ImOrig = histeq(ImOrig);


%Begin the windowing, a.k.a sectioning  into synapses within windows
%Whilst we're at it we generate some stats from the truth data and stick it
%in a structure for later

WindowNum = size(Locations,1);

for i= 1:1:WindowNum
TempImage = im2bw(zeros(size(ImSynapse)));
TempImage(cc.PixelIdxList{i})=1;

TruthWindow = imcrop(TempImage,[Locationsrange(i,1),Locationsrange(i,2),winsize,winsize]);
TruthWindow = bwmorph(TruthWindow,'dilate',3);
trueconnect = bwconncomp(TruthWindow);
truthstats{i} = regionprops(trueconnect, 'Area','Eccentricity','Perimeter',...
'EquivDiameter','MajorAxisLength', 'MinorAxisLength', 'ConvexArea', 'Solidity', 'Extent');

%Create the same windows from the original image for finding extra features
Imagewindow = imcrop(ImOrig,[Locationsrange(i,1),Locationsrange(i,2),winsize,winsize]);
filename = sprintf('images/%d synapse.tif',i);
filename2 = sprintf('images/%d truth.tif',i);
imwrite(Imagewindow,filename)
imwrite(TruthWindow,filename2)
end


%Add new features here make sure they go into the next column
%Also make sure traner0 and trainer1 are exactly the same!!!
%Preferably create a function, as an example see grey detect
%It's your choice whether you want to use stats from the truth window a.k.a
%black n white or the original image window a.k.a grey. Both will give
%working features providing you only put a !single! value into the column 
%per window.

for j = 1:WindowNum
[vesnum, weighted] = vesdetect(j,winsize);
FeatureList(j,1) = vesnum;
[mean,stdev,GreyMin, GreyMax, GreyRange] = greydetect(j);
FeatureList(j,2) = mean;
FeatureList(j,3) = stdev;
FeatureList(j,4) = truthstats{j}.Area;
FeatureList(j,5) = truthstats{j}.Eccentricity;
FeatureList(j,6) = truthstats{j}.Perimeter;
FeatureList(j,7) = truthstats{j}.EquivDiameter;
FeatureList(j,8) = truthstats{j}.MajorAxisLength;
FeatureList(j,9) = truthstats{j}.MinorAxisLength;
FeatureList(j,10) = truthstats{j}.ConvexArea;
FeatureList(j,11) = truthstats{j}.Solidity;
FeatureList(j,12) = truthstats{j}.Extent;
FeatureList(j,13) = weighted;
% FeatureList(j,14) = GreyMin;
% FeatureList(j,15) = GreyMax;
% FeatureList(j,16) = GreyRange;
end


load('trained_ensemble.mat'); % gets save from TREEBAG
if size(FeatureList,1)>0
prediction = predict(BaggedEnsemble, FeatureList);

%Now begin window stitching 
%first get the window top left corner for truths

Predictor = str2double(prediction);
Rownum = find(Predictor);
result = im2bw(zeros(1024,1024));
LocationTL= Locationsrange(Rownum,:);

%now stick all those windows into a logical image 

for i = 1:size(Rownum)
    Row = Rownum(i);
    filename = sprintf('%d truth.tif',Row);
    tempim = imread(filename);
    result(LocationTL(i,2):LocationTL(i,2)+winsize,LocationTL(i,1):LocationTL(i,1)+winsize) = tempim;
end

%expand everything to be more inclusive, then plot
result = bwmorph(result,'dilate',2);
else
    result = zeros(1024);

end

