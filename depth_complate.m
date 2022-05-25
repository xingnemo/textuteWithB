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

%% ------ 处理深度数据 ------
% handleDepth=depth_rand(originDepth,7,8,showFigure);
% mask=ones(row,col);
% depthMask=(mask&handleDepth).* handleDepth;

%% -----------   显示边缘   ---------------
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
%% ------- 位置修正 --------
shiftRadius = 10;

dishitu_init = edge;
dishitu_final = edge;


for i=1:shiftRadius
    se = strel('disk',1,8);
    dishitu_init = imdilate(dishitu_init, se);
    dishitu_final = dishitu_final + dishitu_init;
end

shiftMapX = [dishitu_final(:,1),dishitu_final(:,1:end-1)];
shiftMapY = [dishitu_final(1,:);dishitu_final(1:end-1,:)];

displaceX = shiftMapX - dishitu_final;
displaceY = shiftMapY - dishitu_final;


mapx=1:col;      
mapy=(1:row)';     
mapx=repmat(mapx,row,1);
mapy=repmat(mapy,1,col);
mapx0=mapx;          
mapy0=mapy;

for i=1:shiftRadius               
    for u=1:col
        for v=1:row
            nx=mapy(v,u);       
            ny=mapx(v,u);
                if nx<1
                    nx=1;
                end
                if nx>row
                    nx=row;
                end
                if ny<1
                    ny=1;
                end
                if ny>col
                    ny=col; 
                end
            mapx(v,u)=mapx(v,u)+displaceX(nx,ny); 
            mapy(v,u)=mapy(v,u)+displaceY(nx,ny); 
        end
    end
end

if showFigure==0
%     figure,imshow(I);
    mapx1=mapx-mapx0;   
    mapy1=mapy-mapy0;   
    mapx1=imfilter(mapx1,ones(1));    
    mapy1=imfilter(mapy1,ones(1));

end

%% ------ 尺度修正，这部分就是为了确定滤波的范围用多大的才合适，每一个中心像素点周围的区域都不同，所以要用不同的 radius 去处理 ------

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

%% ---------- 
numth=4;    % 灰度阈值分层   %30
[idx,c] = kmeans(oiColors(:,1:end),numth);   % [idx,c] = kmeans(point,k) idx表示每个点属于哪个聚类，C表示聚类质心的坐标
c = uint8(c);   % 转为 0-255

imsclh = originImage;
colorPoints = zeros(row,col);
index = 0;
for i = 1:row
    for j = 1:col
        index = index+1;
        imsclh(i,j,:) = c(idx(index),:);
        colorPoints(i,j) = idx(index); 
    end
end

% if showFigure == 1
    figure,imshow(imsclh),title('色彩量化');  % imsclh 是  色彩量化  的结果
    figure,imagesc(colorPoints),title('色彩分布');  % colorPoints 是  色彩分布  的结果
% end


texture = zeros(row,col,numth);      % texture 变成了 4 种纹理描述图
colorPoints = gpuArray(colorPoints);

for i=1:radius
    h = fspecial('disk',i);
    h = gpuArray(double(h));
    for j=1:numth
        Ibwj = single(colorPoints==j);    % Ibwj 是 色彩分布 colorPoints 中的一种，用j索引
        tmapij = imfilter(Ibwj,h,'symmetric');
        tmapj = texture(:,:,j);      % tmapj 是 4种纹理描述图 texture 当中的一个
        tmapj(handleRadius==i) = tmapij(handleRadius==i);   % tmapj
        texture(:,:,j) = tmapj;
    end
end

texture2 =texture;


for i = 1:row
    for j = 1:col
        nx = mapy(i,j);
        ny = mapx(i,j);
        if nx<1
            nx=1;
        end
        if nx>row
            nx=row;
        end
        if ny<1
            ny=1;
        end
        if ny>col
            ny=col;
        end
        texture2(i,j,:)=texture(nx,ny,:);   % 这个节里面的内容，应该是把纹理描述图，进行了一个处理，用到了mapx和mapy，
    end
end

%% ------ 调用 depth_rand 函数，从Ground Truth中抽样取点，自定义 sparse depth map------
path = '.\data\';
name = '00001';
[depth,image]=read_h5(path,name);
[mask,depthMask] = depth_rand(depth,5,5,0);   % 以上：获得了稀疏深度图 ---------


%% ------ 转变思路：选半径的方法 ------
channelContainer = zeros(row,col,radius);
for channel = 1:radius
    h = fspecial('disk',channel);  
    resultCount = filter2(h,mask);              % mask  只是0-1掩码
    resultValue = filter2(h,depthMask);        % depthMask 用掩码对位相乘后的稀疏深度图 
    channelContainer(:,:,channel) = resultValue ./ resultCount;
end 

result = zeros(row,col);

for i = 1:row
    for j = 1:col
        if depthMask(i,j) ~= 0
            result(i,j)=depthMask(i,j);
        else
            delta_x = mapx1(i,j);
            delta_y = mapy1(i,j);
            if delta_x<1
                delta_x=1;
            end
            if delta_x+i>row
                delta_x=row-i;
            end
            if delta_y<1
                delta_y=0;
            end
            if delta_y+j>col
                delta_y=col-j;
            end
            result(i,j) = channelContainer(max(1,i+delta_x),max(1,j+delta_y),handleRadius(max(1,i+delta_x),max(1,j+delta_y)));
        end
    end
end

figure,imagesc(result),title('result');

% figure('name','result','NumberTitle','off'),imshow(result,[]);
% figure('name','result','NumberTitle','off'),imagesc(result);


%% --------------- 轮廓处理 ---------------
% contourRadius=10;   
% hclEdge = handle_contour_line(edge,contourRadius,showFigure);
% smoothArea =~ (mask & hclEdge);
% figure,imshow(smoothArea),title('smoothArea');
% 
% tmp1 = colorPoints.*smoothArea;
% figure,imagesc(tmp1),title('tmp1');

% tmp2 = depthMask.*smoothArea;
% figure,imshow(tmp2),title('tmp2');


toc