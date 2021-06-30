%% Image Processing for Materials Science Applications
% Automatic Size Calculation
% Written by Ofir Friedman 300483153
% Written in Matlab R2013a
% ofirfr@post.bgu.ac.il


function ASC_OfirFriedman()

close all;

%Rescaling is required due to hardware limitations only
RescaleSize=0.8;

%Image resolution:
prompt = 'Please insert image resolution in nm:\n';
img_res=input(prompt); %nm


%Finds pixel to nm ratio
nm_per_plx = CalculateNMPerPLX(img_res,RescaleSize);

%A scale found from trial and error
%for background noise removal
SmallestObjectToRemove=-26*img_res+2033;

% A loop is created to allow different scan
% angles of the imclose function.
% a 20 degree scan from 0 to 180 has found
% to produce a proper result.
% 180 degrees scan is possible but requires
% additional computing time and will much
% necessarily produce a significantly different results.
counter=0;
for angleofScan=0:20:180

    counter=counter+1;
    
    %Collect Image and transform its histogram to grayscale 
    I = imread('Target.tif');    
    I = imresize(I,RescaleSize);   
    I= imcrop(I,[0 0 820 730]);
    I = rgb2gray(I);
    
    %Create a new image using imclose function on the original image
    %Using lines for 20 pixels at a given angle.
    %imclose function conducting Erosion and Dilation 
    background = imclose(I,strel('line',20,angleofScan));
   
    %Perform  Erode using disk form of 5 pixels
    background = imerode(background,strel('disk',5));
 
    %Create a new image containing the difference
    %between the processed image and the original image
    I2= background - I;

    %Spead the difference image histogram to both edges
    I3 = imadjust(I2);
     
    %Finds the image threshold using Otsu's method
    %Once found the image is converted to black and white
    level = graythresh(I3);
    bw = im2bw(I3,level);
    
    %Background noise is removed
    bw2 = bwareaopen(bw, SmallestObjectToRemove);
    
    %Create an arrays of objects each containing
    %an arrays of pixels of the object
    %objects are a white area surrounded by black pixels
    cc(counter) = bwconncomp(bw2, 8);
   
   %Generate a structues based arrays of all
   %the object in all images that were generated
   %in different scan angles. The data contains
   %major and minor asix leangth of each and every object
   %detected during the scan
   if counter==1
       
     graindataMajorArray.graindataMajor = regionprops(cc, 'MajorAxisLength');
     graindataMinorArray.graindataMinor = regionprops(cc, 'MinorAxisLength');

    %Initiate  final result by 
    %simply collecting the first image
    FinalImage = bw2;

   else
       
     graindataMajorArray(counter).graindataMajor = regionprops(cc(counter), 'MajorAxisLength');
	 graindataMinorArray(counter).graindataMinor = regionprops(cc(counter), 'MinorAxisLength');
       
   end
    
end

%Initiate  final result by 
%simply using the first image data
ccFinal = cc(1);

%Scan and compare Images
FinalImageColor = uint8(FinalImage);
for compareCounter=2:1:counter

    %Scan each object in the image and compare it to the 
    %first processed image object. If a new item is found
    %it is added to the "FinalImage".
    
    %New image - Object look
    for NewObjectNumber=1:1:cc(compareCounter).NumObjects
    
        FlagObjectFound=0;
        
        %Final image - objects loop
        for FinalObjectNumber=1:1:ccFinal.NumObjects
        
            %determine if there is a reasonable familiarity between objects      
           FamiliarObject = sum(FinalImage(cell2mat(cc(compareCounter).PixelIdxList(NewObjectNumber))) >=1)/length(cell2mat(cc(compareCounter).PixelIdxList(NewObjectNumber))) * 100;

            if isequal(cc(compareCounter).PixelIdxList(NewObjectNumber),ccFinal.PixelIdxList(FinalObjectNumber)) || FamiliarObject>= 90 
                FlagObjectFound=1;
                break;
            end

        end
        
        if FlagObjectFound==0
            %Update final image
            FinalImage(cell2mat(cc(compareCounter).PixelIdxList(NewObjectNumber)))=1;
            FinalImageColor(cell2mat(cc(compareCounter).PixelIdxList(NewObjectNumber)))=compareCounter*30;
            
            %Update final image objects data
            ccFinal.Connectivity=ccFinal.Connectivity+1;
            ccFinal.NumObjects=ccFinal.NumObjects+1;
            ccFinal.PixelIdxList(ccFinal.NumObjects)=cc(compareCounter).PixelIdxList(NewObjectNumber);
   
        end
        
    end
    
end

rgbImage = ind2rgb(FinalImageColor, colormap(jet));
figure, imshow(rgbImage);

ccFinalRescaled8 = bwconncomp(FinalImage, 8);
FinalDataMajorPixles = regionprops(ccFinalRescaled8, 'MajorAxisLength');
FinalDataMinorPixles = regionprops(ccFinalRescaled8, 'MinorAxisLength');

for Count=1:1:ccFinalRescaled8.NumObjects
    FinalDataMajornm(Count) = nm_per_plx*FinalDataMajorPixles(Count).MajorAxisLength;
    FinalDataMinornm(Count) = nm_per_plx*FinalDataMinorPixles(Count).MinorAxisLength;
end
%export data to excle
    
    MajorAxisLength = 'MajorAxisLength.xlsx';
    xlswrite(MajorAxisLength,FinalDataMajornm(:));
    
      
    MinorAxisLength = 'MinorAxisLength.xlsx';
    xlswrite(MinorAxisLength,FinalDataMinornm(:));  
    
end

%%
% Extract the scale bar from the picture
% Calculate its length and returns the 
% pixel and nm ratio: 1 pixed = PlxPerNM nm
function NMPerPlx = CalculateNMPerPLX(img_res,RescaleSize)

    I = imread('Target.tif');
    I = imresize(I,RescaleSize);
    I = rgb2gray(I);
    I= imcrop(I,[0 750 500 50]);

    background = imclose(I,strel('line',50,0));

    I3=background;
    level = graythresh(I3);
    bw = im2bw(I3,level);

    bw2 = 1- bwareaopen(bw, 50);

    %presents the scale bar:
    figure, imshow(bw2);

    cc = bwconncomp(bw2, 8);
    tmp = regionprops(cc, 'BoundingBox');
    graindataMajor = tmp.BoundingBox(3) + 2;

    NMPerPlx=(img_res*RescaleSize)/graindataMajor;
      
end
