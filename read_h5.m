function [depth,image] = read_h5(path,name)
tic

filename = [path,name,'.h5'];
depth=h5read(filename,'/depth');
image=h5read(filename,'/rgb');

show=0;   %   是否信息
if show==1
    h5disp(filename);
end

end 