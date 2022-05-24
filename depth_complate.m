clc
clear
close all
tic

%%  ---------------------- 数据输入 -------------------------
showFigure = 1;
path = './data/';
name = '00001';
[depth,image]=read_h5(path,name);
edge=edge_handle(depth,image);
edgeBinaryImage = double(edge);                  
originImage = image;   
% if showFigure==1
%     Iedge=originImage; 
%     figure,imshow(Iedge),title('Iedge');  
%     edgeFinal=uint8(edgeBinaryImage.*255);     %  edgeFinal 是为 edgeBinaryImage 的uint8类型，0-255，edge 是细化的边缘
%     Iedge(:,:,1)=Iedge(:,:,1)-edgeFinal;  %  这是三个通道的显示效果，1和3剪掉了细化的边缘，2是绿色，突出显示
%     Iedge(:,:,2)=Iedge(:,:,2)+edgeFinal;
%     Iedge(:,:,3)=Iedge(:,:,3)-edgeFinal;
%     figure,imshow(Iedge),title('Iedge'); 
% end

%% ---------------------- 做形态学处理  --------------------------
radiusTmp=20;       %  radiusTmp 表示：移动区
radius=50;          %  radius 表示：变R区，优化数值 80
se = strel('disk',radiusTmp,8);
dilatedEdgeBinaryImage1 = imdilate(edgeBinaryImage,se);               
se = strel('disk',radius,8);
dilatedEdgeBinaryImage2 = imdilate(edgeBinaryImage,se);
dilatedEdgeBinaryImage = edgeBinaryImage+dilatedEdgeBinaryImage1+dilatedEdgeBinaryImage2;
if showFigure==1
    figure,imagesc(dilatedEdgeBinaryImage),title('决策分布图');
end

[ebiRow,ebiCol]=size(edgeBinaryImage);
ebi1=edgeBinaryImage;                        
ebi2=edgeBinaryImage;                        
for i=1:radiusTmp
    se = strel('disk',1,8);
    ebi1 = imdilate(ebi1,se);
    ebi2=ebi2+ebi1;
%     figure(99),imagesc(ebi2),title('地势图');         % 地势图输出显示位置 
%     pause(1);
%     drawnow;               % 眼看着一层一层叠加起来的,这个环节是要写在循环里的，此处的位置刚好是对的
end

%% ---------------------- 描述区域（圆心位置）校正！--------------------
ebiColTmp=[ebi2(:,1),ebi2(:,1:end-1)];           % ebiColTmp 是向右侧，窜了一列 x方向
ebiRowTmp=[ebi2(1,:);ebi2(1:end-1,:)];           % ebiRowTmp 是向下，窜了一行
ebiColDiff=ebiColTmp-ebi2;
ebiRowDiff=ebiRowTmp-ebi2;
% if showFigure==1
%      figure,imagesc(ebiColDiff),title('vx-速度图');       % 逐列和逐行的匀速运动，
%      figure,imagesc(ebiRowDiff),title('vy-速度图');       % dx和dy的值，0 ，-1，1 这三种
%      figure,imagesc(abs(ebiRowDiff)+abs(ebiColDiff)),title('abs(ebiRowDiff)+abs(ebiColDiff)');
% end

newCol=1:ebiCol;       % 设置一行，此处的目的，是获取元素的坐标
newRow=(1:ebiRow)';     % 这个挺复杂，用了算符来解决函数该处理的问题
mapCol=repmat(newCol,ebiRow,1);
mapRow=repmat(newRow,1,ebiCol);
mapColTmp=mapCol;            
mapRowTmp=mapRow;
for i=1:radiusTmp               
    for r=1:ebiRow
        for c=1:ebiCol
            rowValue=mapRow(r,c);   
            colValue=mapCol(r,c);
                if rowValue<1
                    rowValue=1;
                end
                if rowValue>ebiRow
                    rowValue=ebiRow;
                end
                if colValue<1
                    colValue=1;
                end
                if colValue>ebiCol
                    colValue=ebiCol; 
                end
            mapCol(r,c)=mapCol(r,c)+ebiColDiff(rowValue,colValue); 
            mapRow(r,c)=mapRow(r,c)+ebiRowDiff(rowValue,colValue);
        end
    end
%     figure(9999),imagesc(mapCol-mapColTmp);
%     pause(1)
%     drawnow
end
mapColDiff=mapCol-mapColTmp;   % 这个数字，就是x方向和y方向移动了多少
mapRowDiff=mapRow-mapRowTmp;   % 这里的 mapColDiff 是不是就是上面说的 dx的累计和
% if showFigure==1
%     figure,imshow(originImage);
%     mapColDiff=imfilter(mapColDiff,ones(1));    
%     mapRowDiff=imfilter(mapRowDiff,ones(1));
%     rs=0.5;
%     hold on,quiver(imresize(mapColTmp,rs,'nearest'),imresize(mapRowTmp,rs,'nearest'),imresize(mapColDiff,rs,'nearest'),imresize(mapRowDiff,rs,'nearest'),0,'g'),title('圆心校正');
% end

%% ---------------------- 至此，圆心位置校正&矫正后圆心位置显示都结束 ------------------------




%% ---------------------- 尺度，这部分就是为了确定滤波的范围用多大的才合适，每一个中心像素点周围的区域都不同，所以要用不同的 radius 去处理
handleRadius=edgeBinaryImage.*0+radius;   % i 和 i-1 作比较，所以i从2开始遍历，sizee全是50，也就是R2的值;
for i=2:radius
    h = fspecial('disk',i);
    % fspecial 用于创建预定义的滤波算子；disk 参数：circular averaging filter 圆形均值滤波，i表示半径;
    h=h./max(h(:));
    edgeImf=imfilter(edgeBinaryImage,h,'symmetric');  % h的位置叫做滤波模板，'symmetric'是边界选项，此时的edgei的值都是double型;
    edgeImf(edgeImf>0)=1;    % 值为正的位置，值置为 1，此时将edgei中的double型，转换为1；edgei此时是二值图;

    h = fspecial('disk',i-1);
    h = h./max(h(:));
    edgeImf2 = imfilter(edgeBinaryImage,h,'symmetric');
    edgeImf2(edgeImf2>0) = 1;
    edgeImf = edgeImf-edgeImf2;  % 这个做差，理解成，两个半径不同的滤波器，滤过之后的边缘，它们之间的变化;
    handleRadius(edgeImf==1) = i;  % 原本sizee都是50，也就是R2设置的值，现在把出现变化的位置，它的值设置为i;
end

h = fspecial('disk',1);
h=h./max(h(:));  
edgeImf=imfilter(edgeBinaryImage,h);    
edgeImf(edgeImf>0)=1;         
handleRadius(edgeImf==1)=1;      

% if showFigure==1
%     figure,imagesc(handleRadius),title('尺度图');
%     juece=dilatedEdgeBinaryImage;
%     jg=5;
%     xx=mapCol(1:jg:end,1:jg:end);
%     yy=mapRow(1:jg:end,1:jg:end);
% %     xx0=mapColTmp(1:jg:end,1:jg:end);
% %     yy0=mapRowTmp(1:jg:end,1:jg:end);
% %     jue=juece(1:jg:end,1:jg:end);
%     xx=xx(:);   % 把矩阵展平成向量 352*1 维度，原本是 16*22
%     yy=yy(:);
% %     xx0=xx0(:);
% %     yy0=yy0(:);
%     ss=xx.*0;     % 全0，352*1 维
%     jue=xx.*0;     % 全0，352*1 维
%     [row,col,~] = size(originImage);    %  originImage = 480*640
%     for i=1:length(xx)
%         if ismember(xx(i),1:col) && ismember(yy(i),1:row)
%             ss(i) = handleRadius(yy(i),xx(i));  % (handleRadius),title('尺度图')，这个就是在选半径了
%             jue(i) = juece(yy(i),xx(i));  % juece，校正后的圆心位置
%         end
%     end
%     ss=ss-1;
%     ss(ss<0)=1;
% %     figure,imagesc(originImage),title('结果');
% %     hold on,viscircles([xx,yy],ss,'Color','b');
% end

%% ---------------------- 纹理描述，选用了 4 种不同的纹理描述
pointCount=0;
oiColors=zeros(ebiRow*ebiCol,3);
for i=1:ebiRow
    for j=1:ebiCol
        pointCount = pointCount+1; 
        oiColors(pointCount,1)=originImage(i,j,1);   % point 是原图像中，第一个通道，在i，j位置的像素值
        oiColors(pointCount,2)=originImage(i,j,2);
        oiColors(pointCount,3)=originImage(i,j,3);
    end
end

numth=4;    % 灰度阈值分层   %30
[idx,c] = kmeans(oiColors(:,1:end),numth);   % [idx,c] = kmeans(point,k) idx表示每个点属于哪个聚类，C表示聚类质心的坐标
c = uint8(c);   % 转为 0-255

imsclh = originImage;  
handlePoints = zeros(ebiRow,ebiCol);
index = 0;
for i = 1:ebiRow
    for j = 1:ebiCol
        index = index+1;
        imsclh(i,j,:) = c(idx(index),:);
        handlePoints(i,j) = idx(index); 
    end
end

if showFigure == 1
%     figure,imshow(imsclh),title('色彩量化');    % imsclh 是  色彩量化  的结果
%     figure,imagesc(handlePoints),title('色彩分布');    % handlePoints 是  色彩分布  的结果
end

texture = zeros(ebiRow,ebiCol,numth);      % texture 变成了 4 种纹理描述图
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

%%
texture2=texture;    
for i = 1:ebiRow
    for j = 1:ebiCol
        rowValue = mapRow(i,j);
        colValue = mapCol(i,j);
        if rowValue<1
            rowValue=1;
        end
        if rowValue>ebiRow
            rowValue=ebiRow;
        end
        if colValue<1
            colValue=1;
        end
        if colValue>ebiCol
            colValue=ebiCol;
        end
        texture2(i,j,:)=texture(rowValue,colValue,:);    
    end
end

% % ------------------- 当时没有稀疏的深度图，自己创造了一个 --------------------
% % depthImageName = 'our_depth_image';
% depthImageName = '3351';
% ground_truth_depth = imread(['.\testimage02\',depthImageName,'.png']);
% figure,imagesc(ground_truth_depth);title('ground-truth-depth');
% ground_truth_depth = ground_truth_depth./255;
% figure,imagesc(ground_truth_depth);title('uint8-ground-truth-depth');
% hold on,viscircles([xx,yy],ss,'Color','b');
% hold on,viscircles([xx(jue==2),yy(jue==2)],ss(jue==2),'Color','r');  % 就先用这个位置的圆心和半径，作为纹理描述区域;
% mask = zeros(size(ground_truth_depth));  % 这些0，一会就是要被补全的内容;
% jg_depth = 7;
% x = 2:jg_depth:640;
% y = 2:jg_depth:480;
% x = x(:);
% y = y(:);
% 
% for j = 1:length(x)
%     for i = 1:length(y)
%         mask(y(i),x(j)) = 1;
%     end
% end
% 
% figure,imshow(mask),title('zeros-map-imshow');
% % figure,imagesc(zeros_map),title('zeros-map-imagesc');
% % depthMask = uint8(mask).*uint8(ground_truth_depth);
% depthMask = mask.* double(ground_truth_depth);
% % mask 是 0-1的二值矩阵
% % depthMask 是稀疏深度图，也就是待补全的深度图

%% ---------------------- 现在有稀疏的深度图了，不需要自己下采样了 --------------------
% depthImageName = imageName;
depthImage = depth;
[depthRow,depthCol]=size(depthImage);
mask = ones(depthRow,depthCol);
mask = mask&depthImage;
depthMask = mask.* depthImage;

%% ---------------------- 转变思路：选半径的方法 --------------------
channelContainer = zeros(ebiRow,ebiCol,radius);
for channel = 1:radius
    h = fspecial('disk',channel);  
    resultCount = filter2(h,mask);              
    resultCalue = filter2(h,depthMask);        
    channelContainer(:,:,channel) = resultCalue ./ resultCount;
end

result = zeros(ebiRow,ebiCol);
for i = 1:ebiRow
    for j = 1:ebiCol
        if result(i,j) ~= 0
            result(i,j)=depthMask(i,j);
        else
            colDiff = mapColDiff(i,j);
            rowDiff = mapRowDiff(i,j);
            if colDiff<1
                colDiff=1;
            end
            if colDiff+i>ebiRow
                colDiff=ebiRow-i;
            end
            if rowDiff<1
                rowDiff=0;
            end
            if rowDiff+j>ebiCol
                rowDiff=ebiCol-j;
            end
            result(i,j) = channelContainer(max(1,i+colDiff),max(1,j+rowDiff),handleRadius(max(1,i+colDiff),max(1,j+rowDiff)));
        end
    end
end

figure('name','result','NumberTitle','off'),imagesc(result);
%% 
% edgeFinal=uint8(edgeBinaryImage.*255);     %  edgeFinal 是为 edgeBinaryImage 的uint8类型，0-255，edgeBinaryImage 是细化的边缘
% result=result+double(edgeFinal);  %  这是三个通道的显示效果，1和3剪掉了细化的边缘，2是绿色，突出显示
% figure,imshow(result),title('result+edgeBinaryImage');  % 在此，突出显示绿色的细化边缘，在原图（Iedge）上叠加显示出来
toc
