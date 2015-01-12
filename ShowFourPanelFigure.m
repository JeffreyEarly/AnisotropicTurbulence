day = 15000;

addpath('/Users/jearly/Dropbox/Documents/Matlab/jlab')
addpath('../GLOceanKit/Matlab/')
file = '/Volumes/Data/Anisotropy/TurbulenceAnisotropic.nc';
%file = '/Volumes/Data/AnisotropicDataAdam/QGBetaPlaneTurbulenceFloats_experiment_04.nc';
output = '/Users/jearly/Desktop/FourPanel.png';

[x,y,t] = FieldsFromTurbulenceFile( file, 0, 'x', 'y', 't');

height_scale = ncreadatt(file, '/', 'height_scale');
time_scale = ncreadatt(file, '/', 'time_scale');
length_scale = ncreadatt(file, '/', 'length_scale');
vorticity_scale = ncreadatt(file, '/', 'vorticity_scale');
k_f = ncreadatt(file, '/', 'forcing_wavenumber');
k_f_width = ncreadatt(file, '/', 'forcing_width');
k_nu = ncreadatt(file, '/', 'viscous_wavenumber');
k_alpha = ncreadatt(file, '/', 'thermal_damping_wavenumber');
k_r = ncreadatt(file, '/', 'frictional_damping_wavenumber');
f_zeta = ncreadatt(file, '/', 'f_zeta');
latitude = ncreadatt(file, '/', 'latitude');
k_max = ncreadatt(file, '/', 'max_resolved_wavenumber');
r = ncreadatt(file, '/', 'r');
g = 9.81;

if (k_alpha > k_r)
	k_damp = k_alpha;
else
	k_damp = k_r;
end

t = t/86400;

timeIndex = find( t <= day, 1, 'last');
%
% timeIndex = 47
[u, v, rv, ssh, sshFD, force, k, l, f0] = FieldsFromTurbulenceFile( file, timeIndex, 'u', 'v', 'rv', 'ssh', 'ssh_fd', 'force', 'k', 'l', 'f0');
%[u, v, rv, ssh, sshFD, k, l, f0] = FieldsFromTurbulenceFile( file, timeIndex, 'u', 'v', 'rv', 'ssh', 'ssh_fd', 'k', 'l', 'f0');


figure
theForce = pcolor(x, y, force);
theForce.EdgeColor = 'none';
fprintf('max ssh: %g, max force: %g, max rv: %g\n', max(max(ssh)), max(max(force)), max(max(rv/f0)))
 
theFigure = figure('Position', [50 50 1000 1000]);
theFigure.PaperPositionMode = 'auto';
theFigure.Color = 'white';


%%%%%%%%%%%%%%%%%%%%%
%
% SSH Plot
%
%%%%%%%%%%%%%%%%%%%%%%

sshPlot = subplot(2,2,1);
theSSH = pcolor(x, y, ssh);
theSSH.EdgeColor = 'none';
axis(sshPlot, 'equal', 'tight');
sshPlot.Title.String = 'SSH';
sshPlot.XTick = [];
sshPlot.YTick = [];
colormap(sshPlot,gray(1024))

%%%%%%%%%%%%%%%%%%%%%
%
% RV Plot
%
%%%%%%%%%%%%%%%%%%%%%%

rvPlot = subplot(2,2,2);
theRV = pcolor(x, y, rv);
theRV.EdgeColor = 'none';
axis(rvPlot, 'equal', 'tight');
rvPlot.Title.String = 'Relative vorticity';
rvPlot.XTick = [];
rvPlot.YTick = [];
colormap(rvPlot,gray(1024))

%%%%%%%%%%%%%%%%%%%%%
%
% Speed Plot
%
%%%%%%%%%%%%%%%%%%%%%%

speed = sqrt( u.*u + v.*v );
u = u./speed;
v = v./speed;
stride=20;

speedPlot = subplot(2,2,3);
theSpeedRaster = pcolor(x, y, speed);
theSpeedRaster.EdgeColor = 'none';
hold on
theSpeedQuiver = quiver(x(1:stride:end),y(1:stride:end),u(1:stride:end,1:stride:end),v(1:stride:end,1:stride:end), 'black');
hold off
speedPlot.Title.String = 'Snapshot of the Eulerian Velocity Field';
speedPlot.XTick = [];
speedPlot.YTick = [];
%axis(speedPlot, 'equal', 'tight');

fprintf('max ssh: %.4g cm, max rv: %.2g f0, max speed: %.4g cm/s\n', max(max(abs(ssh)))*100, max(max(abs(rv)/f0)), max(max(speed))*100)

%%%%%%%%%%%%%%%%%%%%%
%
% Energy Plot
%
%%%%%%%%%%%%%%%%%%%%%%

energyPlot = subplot(2,2,4);

[kMag, energyMag] = EnergySpectrumFromSSH( sshFD, k, l, g, f0, length_scale );

enstrophyStartIndex = find( kMag > k_f + k_f_width/2, 1, 'first')+1;
enstrophyEndIndex = find( kMag < k_nu, 1, 'last')-1;

energyStartIndex = 2;
energyEndIndex = find( kMag < k_f - k_f_width/2, 1, 'last')-1;

% This coefficient will place a k^-3 line just above the enstrophy cascade region
enstrophyCoeff = 10^(log10( energyMag(enstrophyStartIndex) ) + 0.5 +3*log10( kMag(enstrophyStartIndex) ));


loglog(kMag, energyMag, 'blue', 'LineWidth', 1.5)
hold on
loglog(kMag(enstrophyStartIndex:enstrophyEndIndex),  enstrophyCoeff*(kMag(enstrophyStartIndex:enstrophyEndIndex)).^(-3), 'black', 'LineWidth', 1.0)
hold off

vlines(  k_f - k_f_width/2 );
vlines(  k_f + k_f_width/2 );
vlines(  k_nu );
vlines(  k_damp );

xlabel('k')
ylabel('E(k)')

xl = 10^( log10(kMag(enstrophyStartIndex)) + (log10(kMag(enstrophyEndIndex))-log10(kMag(enstrophyStartIndex)))/2);
yl = (10^0.5)*enstrophyCoeff*xl^(-3);
text(double(xl), double(yl), 'k^{-3}') 

(log10(energyMag(enstrophyEndIndex))-log10(energyMag(enstrophyStartIndex)))/(log10(kMag(enstrophyEndIndex))-log10(kMag(enstrophyStartIndex)))

% This coefficient will place a k^-5/3 line just above the energy cascade region
if (energyEndIndex > energyStartIndex)
	energyCoeff = 10^(log10( energyMag(energyEndIndex) ) + 0.5 + (5/3)*log10( kMag(energyEndIndex) ));
	hold on
	loglog(kMag(energyStartIndex:energyEndIndex),  energyCoeff*(kMag(energyStartIndex:energyEndIndex)).^(-5/3), 'black', 'LineWidth', 1.0)
	hold off
	xl = 10^( log10(kMag(energyStartIndex)) + (log10(kMag(energyEndIndex))-log10(kMag(energyStartIndex)))/2);
	yl = (10^0.5)*energyCoeff*xl^(-5/3);
	text(double(xl), double(yl), 'k^{-5/3}') 
end

title('Eulerian Energy Spectrum')
xlim([min(abs(k(find(abs(k)>0)))) max(abs(k))])
ylim([energyMag(enstrophyEndIndex)/100 10*max(energyMag)])

set( gca, 'xtick', [])
set( gca, 'ytick', [])

%packcols(2,2)

ScaleFactor = 4;
% print(sprintf('-r%d',72*ScaleFactor), '-dpng', output );