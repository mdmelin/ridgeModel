function generateVideo(savepath,moviemat,framerate)

v = VideoWriter(savepath);
v.FrameRate = framerate; open(v);
for i = 1:size(moviemat,4) %trials
    onetrial = moviemat(:,:,:,i);
    for j = 1:size(moviemat,3) %frames
        imagesc(onetrial(:,:,j));
        text(15,15,0,['i = ' num2str(i) '. j = ' num2str(j) '.'],'Color','red','FontSize',15);
        frame = getframe(gcf);
        writeVideo(v,frame)
    end
end
v.close %everything looks good here
end