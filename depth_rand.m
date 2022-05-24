function [data] = depth_rand(depth,rowInterval,colInterval)
tic

[row,col] = size(depth);
mask = zeros(row,col); 
ri = 2:rowInterval:row;
ci = 2:colInterval:col;
r = ri(:);
c = ci(:);
for i = 1:length(r)
    for j = 1:length(c)
        mask(r(i),c(j)) = 1;
    end
end

data = mask.*double(depth);

showFigure=0;
if showFigure==1
    figure,imshow(depth,[]);title('depth');
    figure,imshow(mask),title('mask');
    figure,imshow(data);title('rand-depth');
end

end