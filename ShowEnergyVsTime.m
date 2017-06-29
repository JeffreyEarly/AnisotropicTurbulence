% addpath('/Users/jearly/Dropbox/Documents/Matlab/jlab')
% addpath('../GLOceanKit/Matlab/')
file = '/Volumes/OceanTransfer/IsotropicExperiments/StrongForcing/TurbulenceIsotropic@x2.nc';

g = 9.81;
L_R = ncreadatt(file, '/', 'length_scale');

[x,y,t] = FieldsFromTurbulenceFile( file, 0, 'x', 'y', 't');

n = 10;
indices = 1:ceil(length(t)/n):length(t);
if indices(end) ~= length(t)
    indices(end+1)=length(t);
end

totalEnergy = zeros(length(indices),1);
for iIndex=1:length(indices)
    timeIndex = indices(iIndex);
    [sshFD, k, l, f0] = FieldsFromTurbulenceFile( file, timeIndex, 'ssh_fd', 'k', 'l', 'f0');
    [kMag, energyMag] = EnergySpectrumFromSSH( sshFD, k, l, g, f0, L_R );
    totalEnergy(iIndex) = trapz(kMag,energyMag);
end

figure
plot(t(indices)/86400,totalEnergy)