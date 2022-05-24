function [data] = handle_contour_line(edge,radius,showFigure)
tic

temp=edge;
result=edge; 
for i=1:radius
    se = strel('disk',1,8);
    temp = imdilate(temp,se);
    result=result+temp;
%     if showFigure==1
%         figure(radius),imagesc(result),title('地势图');   
%         pause(1);
%         drawnow;               % 眼看着一层一层叠加起来的,这个环节是要写在循环里的，此处的位置刚好是对的
%     end
end
data = result;

if showFigure==1
    figure;imshow(data,[]);title('edge');
end

end