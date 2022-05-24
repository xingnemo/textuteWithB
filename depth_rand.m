function [data] = depth_rand(depth,rowInterval,colInterval,showFigure)
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

if showFigure==1
    figure,imshow(data);title('rand-depth');
end

end