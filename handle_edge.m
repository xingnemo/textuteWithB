function [imageBW,depthBW,data] = handle_edge(depth,image,showFigure)

image=rgb2gray(image);
imageBW = edge(image,'canny');
depthBW = edge(depth,'canny');
% data = imabsdiff(imageBW,depthBW);
data = imageBW|depthBW;

if showFigure==1
    figure,imshow(imageBW),title('imageBW');
    figure,imshow(depthBW),title('depthBW');
    figure,imshow(data,[]),title('edge');
end

end