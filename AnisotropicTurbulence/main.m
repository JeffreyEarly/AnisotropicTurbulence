//
//  main.m
//  AnisotropicTurbulence
//
//  Created by Jeffrey J. Early on 1/5/15.
//  Copyright (c) 2015 Jeffrey J. Early. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GLNumericalModelingKit/GLNumericalModelingKit.h>
#import <GLOceanKit/GLOceanKit.h>

typedef NS_ENUM(NSUInteger, ExperimentType) {
	kIsotropicExperimentType = 0,
	kAnisotropicExperimentType = 1
};

int main(int argc, const char * argv[]) {
	@autoreleasepool {
		ExperimentType experiment = kAnisotropicExperimentType;
		GLFloat domainWidth = (2*M_PI)*2*611e3; // m
		NSUInteger nPoints = 256;
		NSUInteger aspectRatio = 1;
        
        GLFloat nonLinearFactor = 1;
		
		//NSURL *baseFolder = [NSURL fileURLWithPath: [NSSearchPathForDirectoriesInDomains(NSDesktopDirectory, NSUserDomainMask, YES) firstObject]];
		NSURL *baseFolder = [NSURL fileURLWithPath: @"/Volumes/seattle_data1/jearly/AnisotropyExperiments/GalperinRegime/"];
		NSString *baseName = experiment == kIsotropicExperimentType ? @"TurbulenceIsotropic" : @"TurbulenceAnisotropic";
		NSFileManager *fileManager = [[NSFileManager alloc] init];
		
		GLDimension *xDim = [[GLDimension alloc] initDimensionWithGrid: kGLPeriodicGrid nPoints:nPoints domainMin:-domainWidth/2.0 length:domainWidth];
		xDim.name = @"x";
		GLDimension *yDim = [[GLDimension alloc] initDimensionWithGrid: kGLPeriodicGrid nPoints:nPoints/aspectRatio domainMin:-domainWidth/(2.0*aspectRatio) length: domainWidth/aspectRatio];
		yDim.name = @"y";
		
		GLEquation *equation = [[GLEquation alloc] init];
		
		NSURL *restartURLx1 = [baseFolder URLByAppendingPathComponent: [baseName stringByAppendingString: @"@x1.nc"]];
		if (![fileManager fileExistsAtPath: restartURLx1.path])
		{
			Quasigeostrophy2D *qgSpinup = [[Quasigeostrophy2D alloc] initWithDimensions: @[xDim, yDim] depth: 0.80 latitude: 1.8 equation: equation];
			qgSpinup.shouldUseBeta = experiment == kIsotropicExperimentType ? NO : YES;
			qgSpinup.shouldUseSVV = YES;
			qgSpinup.shouldAntiAlias = YES;
			qgSpinup.shouldForce = YES;
			qgSpinup.forcingFraction = 2.0; // Try chaging this to say, 12---it's a very dramatic qualitative difference
			qgSpinup.forcingWidth = 1;
			qgSpinup.f_zeta = .1/nonLinearFactor;
			qgSpinup.forcingDecorrelationTime = HUGE_VAL;
			qgSpinup.thermalDampingFraction = 0.0;
			qgSpinup.frictionalDampingFraction = 3;
			
			qgSpinup.outputFile = restartURLx1;
			qgSpinup.shouldAdvectFloats = NO;
			qgSpinup.shouldAdvectTracer = NO;
			qgSpinup.outputInterval = nonLinearFactor*86400.;
			
			[qgSpinup runSimulationToTime: 250*nonLinearFactor*86400];
		}
		
		NSURL *restartURLx2 = [baseFolder URLByAppendingPathComponent: [baseName stringByAppendingString: @"@x2.nc"]];
		if (![fileManager fileExistsAtPath: restartURLx2.path])
		{
			Quasigeostrophy2D *qgSpinup = [[Quasigeostrophy2D alloc] initWithFile:restartURLx1 resolutionDoubling:YES equation: equation];
			qgSpinup.shouldForce = YES;
			
			qgSpinup.outputFile = restartURLx2;
			qgSpinup.shouldAdvectFloats = NO;
			qgSpinup.shouldAdvectTracer = NO;
			qgSpinup.outputInterval = 10*86400.;
			
			[qgSpinup runSimulationToTime: 31*86400];
		}
		
		NSURL *restartURLx4 = [baseFolder URLByAppendingPathComponent: [baseName stringByAppendingString: @"@x4.nc"]];
		if (![fileManager fileExistsAtPath: restartURLx4.path])
		{
			Quasigeostrophy2D *qgSpinup = [[Quasigeostrophy2D alloc] initWithFile:restartURLx2 resolutionDoubling:YES equation: equation];
			qgSpinup.shouldForce = YES;
			
			qgSpinup.outputFile = restartURLx4;
			qgSpinup.shouldAdvectFloats = NO;
			qgSpinup.shouldAdvectTracer = NO;
			qgSpinup.outputInterval = 1*86400.;
			
			[qgSpinup runSimulationToTime: 3*86400];
		}
		
		Quasigeostrophy2D *qg = [[Quasigeostrophy2D alloc] initWithFile:restartURLx4 resolutionDoubling:NO equation: equation];
		qg.shouldForce = YES;
		
		qg.outputFile = [baseFolder URLByAppendingPathComponent: [baseName stringByAppendingString: @".nc"]];
		qg.shouldAdvectFloats = YES;
		qg.shouldAdvectTracer = NO;
		qg.outputInterval = 1*86400.;
		
		[qg runSimulationToTime: 1000*86400];
	}
	return 0;
}
