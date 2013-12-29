t=colormap('rainbow');
t=floor(round(t.*255));

fid = fopen('rainbow.txt','w')


function str = get_ledstr(ledID,R,G,B)
  str = sprintf('\\x%s\\x%s\\x%s\\x%s',...
		dec2hex(ledID,2),...
		dec2hex(R,2),...
		dec2hex(G,2),...
		dec2hex(B,2));
end



function str = getcolorpre()
  str = sprintf('\\x42\\x01');
  





numleds=5
all_st = getcolorpre();

for i=5:size(t,1)


  for j=1:numleds

    led_color = 
    ledID = j
    str = get_ledstr(ledID,R,G,B)

    
    
    fprintf(fid, 
  end
		    

end
fclose(fid)
