function [data] = edge_handle(depth,image)
tic

% [depth,image]=read_h5(path,name);
image=rgb2gray(image);
imageBW = edge(image,'canny');
depthBW = edge(depth,'canny');
data = imabsdiff(imageBW,depthBW);

showFigure=0;   %   是否显示图
if showFigure==1
    figure,imshow(image,[]);
    figure,imshow(imageBW)
    figure,imshow(depth,[]);
    figure,imshow(depthBW)
    figure;imshow(data,[]);title('edge');
end

end