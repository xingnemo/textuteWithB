clc
clear
close all
tic

%%  ------ 数据输入 ------
showFigure = 0;
path = './data/';
name = '00001';
[originDepth,originImage]=read_h5(path,name);
[row,col]=size(originDepth);  
[imageEdge,depthEdge,edge]=handle_edge(originDepth,originImage,showFigure);
edge=double(edge); 
              
%% ------ 轮廓处理 ------   
radiusTmp=10;   
hclEdge = handle_contour_line(edge,radiusTmp,showFigure);

%% ------ 尺度，这部分就是为了确定滤波的范围用多大的才合适，每一个中心像素点周围的区域都不同，所以要用不同的 radius 去处理 ------
radius=50; 
handleRadius=edge.*0+radius; 
for i=2:radius
    h = fspecial('disk',i);
    h=h./max(h(:));
    edgeImf=imfilter(edge,h,'symmetric');  
    edgeImf(edgeImf>0)=1;    % 值为正的位置，值置为 1，此时将edgei中的double型，转换为1；edgei此时是二值图;

    h = fspecial('disk',i-1);
    h = h./max(h(:));
    edgeImf2 = imfilter(edge,h,'symmetric');
    edgeImf2(edgeImf2>0) = 1;
    edgeImf = edgeImf-edgeImf2;  % 这个做差，理解成，两个半径不同的滤波器，滤过之后的边缘，它们之间的变化;
    handleRadius(edgeImf==1) = i;  % 原本sizee都是50，也就是R2设置的值，现在把出现变化的位置，它的值设置为i;
end

h = fspecial('disk',1);
h=h./max(h(:));  
edgeImf=imfilter(edge,h);    
edgeImf(edgeImf>0)=1;         
handleRadius(edgeImf==1)=1; 

%% ------ 纹理描述 ------
pointCount=0;
oiColors=zeros(row*col,3);
for i=1:row
    for j=1:col
        pointCount = pointCount+1; 
        oiColors(pointCount,1)=originImage(i,j,1);
        oiColors(pointCount,2)=originImage(i,j,2);
        oiColors(pointCount,3)=originImage(i,j,3);
    end
end

numth=4;    % 灰度阈值分层   %30
[idx,c] = kmeans(oiColors(:,1:end),numth);   % [idx,c] = kmeans(point,k) idx表示每个点属于哪个聚类，C表示聚类质心的坐标
c = uint8(c);   % 转为 0-255

imsclh = originImage;  
handlePoints = zeros(row,col);
index = 0;
for i = 1:row
    for j = 1:col
        index = index+1;
        imsclh(i,j,:) = c(idx(index),:);
        handlePoints(i,j) = idx(index); 
    end
end

if showFigure == 1
%     figure,imshow(imsclh),title('色彩量化');    % imsclh 是  色彩量化  的结果
    figure,imagesc(handlePoints),title('色彩分布');    % handlePoints 是  色彩分布  的结果
end

texture = zeros(row,col,numth);      % texture 变成了 4 种纹理描述图
for i=1:radius  
    h = fspecial('disk',i);
    for j=1:numth
        Ibwj = single(handlePoints==j);    % Ibwj 是 色彩分布 handlePoints 中的一种，用j索引
        tmapij = imfilter(Ibwj,h,'symmetric');
        tmapj = texture(:,:,j);      % tmapj 是 4种纹理描述图 texture 当中的一个
        tmapj(handleRadius==i) = tmapij(handleRadius==i);   % tmapj
        texture(:,:,j) = tmapj;
    end
end

%% ------ 处理深度数据 ------
handleDepth = depth_rand(originDepth,7,8,showFigure);
[depthRow,depthCol]=size(handleDepth);
mask = ones(depthRow,depthCol);
mask = mask&handleDepth;
depthMask = mask.* handleDepth;

%% ------ 转变思路：选半径的方法 ------
channelContainer = zeros(row,col,radius);
for channel = 1:radius
    h = fspecial('disk',channel);  
    resultCount = filter2(h,mask);              
    resultValue = filter2(h,depthMask);        
    channelContainer(:,:,channel) = resultValue ./ resultCount;
end

result = zeros(row,col);
for i = 1:row
    for j = 1:col
        if depthMask(i,j) ~= 0
            result(i,j)=depthMask(i,j);
        else
%             colDiff = mapColDiff(i,j);
%             rowDiff = mapRowDiff(i,j);
%             if colDiff<1
%                 colDiff=1;
%             end
%             if colDiff+i>row
%                 colDiff=row-i;
%             end
%             if rowDiff<1
%                 rowDiff=0;
%             end
%             if rowDiff+j>col
%                 rowDiff=col-j;
%             end
%             result(i,j) = channelContainer(max(1,i+colDiff),max(1,j+rowDiff),handleRadius(max(1,i+colDiff),max(1,j+rowDiff)));
            result(i,j) = channelContainer(i,j,handleRadius(i,j));
        end
    end
end
% figure('name','result','NumberTitle','off'),imshow(result,[]);
figure('name','result','NumberTitle','off'),imagesc(result);
%% 
toc








