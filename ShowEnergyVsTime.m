% addpath('/Users/jearly/Dropbox/Documents/Matlab/jlab')
% addpath('../GLOceanKit/Matlab/')
file = '/Volumes/OceanTransfer/AnisotropicExperiments/StrongForcing/TurbulenceAnisotropic@x4.nc';
% file = '/Volumes/OceanTransfer/AnisotropicExperiments/AnisotropicDataAdam/QGBetaPlaneTurbulenceFloats_experiment_04.nc';

g = 9.81;
L_R = ncreadatt(file, '/', 'length_scale');

[x,y,t] = FieldsFromTurbulenceFile( file, 0, 'x', 'y', 't');

indices = 1:4:length(t);
totalEnergy = zeros(length(indices),1);
i = 1;
for timeIndex=indices
    [sshFD, k, l, f0] = FieldsFromTurbulenceFile( file, timeIndex, 'ssh_fd', 'k', 'l', 'f0');
    [kMag, energyMag] = EnergySpectrumFromSSH( sshFD, k, l, g, f0, L_R );
    totalEnergy(i) = trapz(kMag,energyMag);
    i = i+1;
end

figure
plot(t(indices)/86400,totalEnergy)