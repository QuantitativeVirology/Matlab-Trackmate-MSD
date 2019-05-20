%% make a list of all superfolders
% this part loops through a folder structure and makes a list of folders to
% process.Image data should be in individual folders together with the
% corresponding Trackmate xml file. This code heavily uses MSDanalyzer https://tinevez.github.io/msdanalyzer/

allSuperfolders = {};
num = 1;

path = uigetdir;
expfold = dir(path);
        folders = dir(path);

        for i1 = 1:size(folders, 1)
            if isempty(strfind(folders(i1).name, '.'))
            superfolders = dir(fullfile(folders(i1).folder, folders(i1).name));
        
                for i2 = 1:size(superfolders, 1)
                    if isempty(strfind(superfolders(i2).name, '.'))
                    allSuperfolders{num,1} = fullfile(superfolders(i2).folder, superfolders(i2).name);
                    num = num+1;
                    end
                end
            end
        end
        

% loop through all superfolders and save mat file in each folder next to image

for k=1:length(allSuperfolders)
    
    subdirs = dir(allSuperfolders{k,1});
    
     
for i = 3:size(subdirs,1)
       
           path = fullfile(subdirs(i).folder, subdirs(i).name);
           files = dir(path);
           
        %tic

           file=fullfile(files(4).folder, files(4).name);
           %file
           tracks = fast_large_Trackmate_xml_reader(file);
           fname = fullfile(path,sprintf('tracks_%s.mat',subdirs(i).name));
           parsave(fname, tracks);
        %toc
end
end
        
% loop through all superfolders and combine tracks in a file per experiment folder

for k=1:length(allSuperfolders)
    clear thetracks
    subdirs = dir(allSuperfolders{k,1});
    thetracks={};       
for i = 3:size(subdirs,1)    
           path = fullfile(subdirs(i).folder, subdirs(i).name);
           files = dir(path);
           %tic
           postrigger=0;
            for j = 3:length(files)
                if strfind(files(j).name, '.mat')
                        postrigger=1;
                        file=fullfile(files(j).folder, files(j).name);
                        clear tracks
                        tracks=load(file);
                        thetracks=[thetracks;tracks.tracks];                
                end
            end
            
            if postrigger == 0
                path               
            end 
        save([(allSuperfolders{k,1}), '/thetracks.mat'],'thetracks');
end
end

%% Loops through superfolders, combine all tracks from all "thetracks.mat" and analyze them using MSDanalyzer

for Sufold=3:length(expfold)
    expfolder = expfold(Sufold,1);
    subdirs=dir(fullfile(expfolder.folder, expfolder.name));
        
    %loop through all superfolders and combine tracks in a file per experiment folder

    for k=3:length(subdirs)
        clear alltracks
        alltracks=[];
        subsubdirs = dir(fullfile(subdirs(k).folder, subdirs(k).name));
            for i=3:length(subsubdirs)
    
                        if strfind(subsubdirs(i).name, '.mat')
                            file=fullfile(subsubdirs(i).folder, subsubdirs(i).name);
                            clear thetracks
                            thetracks=load(file);
                            alltracks=[alltracks;thetracks.thetracks];
                        end
            end
        
    end
    subdirs(k).folder   
    save([fullfile(expfolder.folder, expfolder.name), '\alltracks.mat'],'alltracks');


% Loop through Experiment folders and analyze  tracks

    tracks = alltracks;
    folder = [fullfile(expfolder.folder, expfolder.name), '\'];

% define variables

dimension=2;
spaceUnits='um';
timeUnits='s';
minimumtracklength=20;
timeinterval=0.04655;



% initiate MSD analyzer file and plot tracks

filteredtrackslist=[];

for i=1:length(tracks)
    if length(tracks{i,1})>= minimumtracklength

    filteredtrackslist=[filteredtrackslist; tracks(i,1)];
    end
end

% round values in tracks to multiples of timeinterval such that bug in MSDanalyzer is omitted
N=timeinterval; 
filteredtrackslist = cellfun(@(V)multiples(V,N),filteredtrackslist, 'UniformOutput', false);

ma = msdanalyzer(dimension, spaceUnits, timeUnits);
ma = ma.addAll(filteredtrackslist);
figure
ma.plotTracks;
ma.labelPlotTracks;
saveas(gca,[folder, '/' 'Track Plot' '.fig'])

% compute and plot MSDs
ma = ma.computeMSD;
figure
ma.plotMSD;
saveas(gca,[folder, '/' 'MSD Plot' '.fig'])

% compute and plot mean MSD
figure
ma.plotMeanMSD(gca, true)
mmsd = ma.getMeanMSD;
t = mmsd(:,1);
x = mmsd(:,2);
dx = mmsd(:,3) ./ sqrt(mmsd(:,4));
errorbar(t, x, dx, 'k')

figure
[fo, gof] = ma.fitMeanMSD;
plot(fo)
ma.labelPlotMSD;
legend off
saveas(gca,[folder, '/' 'MSD computation Plot' '.fig'])


% compute alphas
ma = ma.fitLogLogMSD(0.5);
ma.loglogfit;
mean(ma.loglogfit.alpha);


r2fits = ma.loglogfit.r2fit;
alphas = ma.loglogfit.alpha;

R2LIMIT = 0.8;

% Remove bad fits
bad_fits = r2fits < R2LIMIT;
fprintf('Keeping %d fits (R2 > %.2f).\n', sum(~bad_fits), R2LIMIT);
alphas(bad_fits) = [];

% T-test
[htest, pval] = ttest(alphas, 1, 0.05, 'left');

if ~htest
    [htest, pval] = ttest(alphas, 1, 0.05);
end

% Prepare string
str = { [ '\alpha = ' sprintf('%.2f � %.2f (mean � std, N = %d)', nanmean(alphas), nanstd(alphas), numel(alphas)) ] };

if htest
    str{2} = sprintf('Significantly below 1, with p = %.2g', pval);
else
    str{2} = sprintf('Not significantly differend from 1, with p = %.2g', pval);
end

figure
hist(alphas, 50);
box off
xlabel('\alpha')
ylabel('#')

yl = ylim(gca);
xl = xlim(gca);
text(xl(2), yl(2)+2, str, ...
    'HorizontalAlignment', 'right', ...
    'VerticalAlignment', 'top', ...
    'FontSize', 16)
title('\alpha values distribution', ...
    'FontSize', 20)
ylim([0 yl(2)+2])

yl = ylim(gca);
xl = xlim(gca);
text(xl(2), yl(2)+2, str, ...
    'HorizontalAlignment', 'right', ...
    'VerticalAlignment', 'top', ...
    'FontSize', 16)
title('\alpha values distribution', ...
    'FontSize', 20)
ylim([0 yl(2)+2])
saveas(gca,[folder, '/' 'Alphas' '.fig'])

% Ordinate at origin of the log-log curve.
gammas = ma.loglogfit.gamma;
gammas(bad_fits) = []; % discard bad fits, like for alpha

Dmean = nanmean( gammas ) / 2 / ma.n_dim;
Dstd  =  nanstd( gammas ) / 2 / ma.n_dim;

fprintf('Estimation of the diffusion coefficient from log-log fit of the MSD curves:\n')
fprintf('D = %.2e � %.2e (mean � std, N = %d)\n', ...
    Dmean, Dstd, numel(gammas));

% save ma file

save([folder, '/data.mat']);


end
