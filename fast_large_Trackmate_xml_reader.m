function [tracks] = fast_large_Trackmate_xml_reader(file)

%read xml file fast using MatlabXML https://github.com/bastibe/MatlabXML
tic
xml = MatlabXML(file);
toc

%extract points properties per frame into cell array

pointvalues=cell(length(xml.Children.Children(1,2).Children(1,2).Children),1); %use here frame number from top header instead?

for i=1:size(xml.Children.Children(1,2).Children(1,2).Children,2)%what happens here if frames have no points?
    for j=1:size(xml.Children.Children(1,2).Children(1,2).Children(1,i).Children,2)
        
        pointvalues{i,1}(j,:)=str2double(values(xml.Children.Children(1,2).Children(1,2).Children(1,i).Children(1,j).Attributes));
    end
end

%make new array in which each ID has txyz values and nothing more
simplepointslist=cell2mat(pointvalues);
ID_t_x_y_z=[simplepointslist(:,4), simplepointslist(:,11), simplepointslist(:,12), simplepointslist(:,13), simplepointslist(:,14)];


%extract track properties

trackvalues=cell(length(xml.Children.Children(1,2).Children(1,3).Children),1);

for i=1:size(xml.Children.Children(1,2).Children(1,3).Children,2)
    for j=1:size(xml.Children.Children(1,2).Children(1,3).Children(1,i).Children,2)
    trackvalues{i,1}(j,:)=values(xml.Children.Children(1,2).Children(1,3).Children(1,i).Children(1,j).Attributes);
    
    end
    
    
end

%make tracks by replacing IDs with txyz values and sort them according to
%time

trackIDs=cell(size(trackvalues,1),1);
for i=1:size(trackvalues,1)
    trackIDs{i,1}=str2double(trackvalues{i,1}(:,7));
end

tracks=cell(size(trackvalues,1),1);
for i=1:size(trackIDs,1)
    for j=1:(size(trackIDs{i,1},1))
        ind = find((ID_t_x_y_z == trackIDs{i,1}(j,1)));
                tracks{i,1}(j,1:3)=ID_t_x_y_z(ind, 2:4);
    end
end
        
for i=1:size(tracks,1)
    tracks{i,1}=sortrows(tracks{i,1});
end


