close all;
clc;
clear;

path = './data/';   
name = '00001';
[depth,image]=read_h5(path,name);
% res_RGF = RollingGuidanceFilter(result, 3, 0.05, 10);
[imageEdge,depthEdge,edge] = handle_edge(depth,image,1);
data1 = imageEdge&depthEdge;
figure;imshow(data1,[]);title('data1');
% data = depth_rand(depth,7,8);

% % image=imread([path,name,'_rgb.png']);
% [depth,image]=read_h5(path,name);
% image=rgb2gray(image);
% figure,imshow(image,[]);
% BW2 = edge(image,'canny');
% figure, imshow(BW2)
% 
% figure,imshow(depth,[]);
% BW1 = edge(depth,'canny');
% figure, imshow(BW1)
% 
% diff = imabsdiff(BW1,BW2);
% figure;imshow(diff,[]);title('diff');
% 
% II = II ./ max(II(:));
% II = II .* 255;
% II = im2gray(II);
% imagesc(II);
% canny_result2 = imresize(double(canny_result),[480 640]);
% 
% figure;
% imshow(canny_result);
% title('canny');
% imwrite(canny_result,[image_name,'_canny_edge2.jpg']);

toc
