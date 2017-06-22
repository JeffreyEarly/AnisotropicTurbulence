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

typedef NS_ENUM(NSUInteger, ForcingStrength) {
    kWeakForcing = 0,
    kModerateForcing = 1,
    kStrongForcing = 2
};

int main(int argc, const char * argv[]) {
	@autoreleasepool {
		ExperimentType experiment = kAnisotropicExperimentType;
        ForcingStrength forcing = kModerateForcing;
		GLFloat domainWidth = (2*M_PI)*2*611e3; // m
		NSUInteger nPoints = 256;
		NSUInteger aspectRatio = 1;
        
		//NSURL *baseFolder = [NSURL fileURLWithPath: [NSSearchPathForDirectoriesInDomains(NSDesktopDirectory, NSUserDomainMask, YES) firstObject]];
		NSURL *baseFolder = [NSURL fileURLWithPath: @"/Volumes/OceanTransfer/AnisotropicExperiments/"];
        if (forcing == kWeakForcing) {
            baseFolder = [baseFolder URLByAppendingPathComponent: @"WeakForcing"];
        } else if (forcing == kModerateForcing) {
            baseFolder = [baseFolder URLByAppendingPathComponent: @"ModerateForcing"];
        } else if (forcing == kStrongForcing) {
            baseFolder = [baseFolder URLByAppendingPathComponent: @"StrongForcing"];
        }
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
            qgSpinup.forcingDecorrelationTime = HUGE_VAL;
			qgSpinup.thermalDampingFraction = 0.0;
			qgSpinup.frictionalDampingFraction = 3;
            qgSpinup.outputFile = restartURLx1;
            qgSpinup.shouldAdvectFloats = NO;
            qgSpinup.shouldAdvectTracer = NO;
            
            GLFloat MaxSimulationTime = 0;
            if (forcing == kWeakForcing) {
                qgSpinup.f_zeta = .001;
                MaxSimulationTime = 1e4 * 86400;
                qgSpinup.outputInterval = 1e2 * 86400.;
            } else if (forcing == kModerateForcing) {
                qgSpinup.f_zeta = .01;
                MaxSimulationTime = 2.5e3 * 86400;
                qgSpinup.outputInterval = 2.5e1 * 86400.;
            } else if (forcing == kStrongForcing) {
                qgSpinup.f_zeta = .1;
                MaxSimulationTime = 1e2 * 86400;
                qgSpinup.outputInterval = 1 * 86400.;
            }
			
			[qgSpinup runSimulationToTime: MaxSimulationTime];
		}
		
		NSURL *restartURLx2 = [baseFolder URLByAppendingPathComponent: [baseName stringByAppendingString: @"@x2.nc"]];
		if (![fileManager fileExistsAtPath: restartURLx2.path])
		{
			Quasigeostrophy2D *qgSpinup = [[Quasigeostrophy2D alloc] initWithFile:restartURLx1 resolutionDoubling:YES equation: equation];
			qgSpinup.shouldForce = YES;
			qgSpinup.outputFile = restartURLx2;
			qgSpinup.shouldAdvectFloats = NO;
			qgSpinup.shouldAdvectTracer = NO;
            
            GLFloat MaxSimulationTime = 0;
            if (forcing == kWeakForcing) {
                MaxSimulationTime = 1e4 * 86400;  // Really maybe 5e3 would be fine
                qgSpinup.outputInterval = 1e2 * 86400.;
            } else if (forcing == kModerateForcing) {
                MaxSimulationTime = 2.5e3 * 86400; // Looks great at 2500 days
                qgSpinup.outputInterval = 2.5e1 * 86400.;
            } else if (forcing == kStrongForcing) {
                qgSpinup.f_zeta = .1;
                MaxSimulationTime = 750 * 86400; // 500 days is bare minimum, more better.
                qgSpinup.outputInterval = 5 * 86400.;
            }
            
			[qgSpinup runSimulationToTime: MaxSimulationTime];
		}
		
//		NSURL *restartURLx4 = [baseFolder URLByAppendingPathComponent: [baseName stringByAppendingString: @"@x4.nc"]];
//		if (![fileManager fileExistsAtPath: restartURLx4.path])
//		{
//			Quasigeostrophy2D *qgSpinup = [[Quasigeostrophy2D alloc] initWithFile:restartURLx2 resolutionDoubling:YES equation: equation];
//			qgSpinup.shouldForce = YES;
//            qgSpinup.outputFile = restartURLx4;
//			qgSpinup.shouldAdvectFloats = NO;
//			qgSpinup.shouldAdvectTracer = NO;
//            
//            GLFloat MaxSimulationTime = 0;
//            if (forcing == kWeakForcing) {
//                MaxSimulationTime = 1e4 * 86400;
//                qgSpinup.outputInterval = 1e2 * 86400.;
//            } else if (forcing == kModerateForcing) {
//                MaxSimulationTime = 1.25e3 * 86400; // Tested.
//                qgSpinup.outputInterval = 1e1 * 86400.;
//            } else if (forcing == kStrongForcing) {
//                qgSpinup.f_zeta = .1;
//                MaxSimulationTime = 5e2 * 86400;
//                qgSpinup.outputInterval = 5 * 86400.;
//            }
//            
//            [qgSpinup runSimulationToTime: MaxSimulationTime];
//		}
		
        NSURL *finalOutput = [baseFolder URLByAppendingPathComponent: [baseName stringByAppendingString: @".nc"]];
        if (![fileManager fileExistsAtPath: finalOutput.path])
        {
            Quasigeostrophy2D *qg = [[Quasigeostrophy2D alloc] initWithFile:restartURLx2 resolutionDoubling:NO equation: equation];
            qg.shouldForce = YES;
            
            qg.outputFile = finalOutput;
            qg.shouldAdvectFloats = YES;
            qg.shouldAdvectTracer = NO;
            qg.outputInterval = 1*86400.;
            
            [qg runSimulationToTime: 2500*86400];
        }
		
	}
	return 0;
}
