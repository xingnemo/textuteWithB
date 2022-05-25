function [mask,data] = depth_rand(depth,rowInterval,colInterval,showFigure)

%% 随机取点

[row,col] = size(depth);
mask_init = zeros(row,col); 
ri = 2:rowInterval:row;
ci = 2:colInterval:col;
r = ri(:);
c = ci(:);
for i = 1:length(r)
    for j = 1:length(c)
        mask_init(r(i),c(j)) = 1;
    end
end
mask = mask_init;
data = mask.*double(depth);

if showFigure==1
    figure,imshow(data);title('rand-depth');
end

end