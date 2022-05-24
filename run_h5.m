close all;
clc;
clear;

path = './data/';
name = '00001';
filename = [path,name,'.h5'];
h5disp(filename);
depthData=h5read(filename,'/depth');
rgbData=h5read(filename,'/rgb');

figure(),
subplot(1,2,1);imshow(rgbData);title('rgbData');
subplot(1,2,2);imshow(depthData,[]);title('depthData');
imwrite(rgbData,[path,name,'_rgb.png']);