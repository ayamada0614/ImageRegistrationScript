#! /bin/bash

# Volume maker for calculating cost function by changing three parameters for BRAINSFitIGT 
# ------------------------------------------------------------------------------------------------------------------------------------------------
# Concept by Atsushi Yamada PhD, Surgical Navigation and Robotics Laboratory (SNR), Brigham and Women's Hospital and Harvard Medical School
# The script is by Junichi Tokuda PhD, Surgical Navigation and Robotics Laboratory (SNR), Brigham and Women's Hospital and Harvard Medical School 
# ----------------------------------------------------------------------------

echo "====================================================================="
echo "Cost Function Calculater by Changing Three Parameters for BRAINSFitIGT"
echo "Scripted by Atsushi Yamada, PhD, Brigham and Women's Hospital and Harvard Medical School"
echo "====================================================================="

# Procedure
# * Execute a script yamada_make_volume.sh to create deformed images by using ROI Bspline
# * Change condition of if loop in itkRegularStepGradientDescentBaseOptimizer.cxx, l.246
# * make at ./Slicer3-lib/Insight-build/
# * execute this script
# * you can obtain the cost function based on MMI in /CalculationResults/CostFunction-txt
# * execute script to create csv file to collect all data

# Custom file
# 1. genericRegistrationHelper.txx
# add a following line at l.409 of genericRegistrationHelper.txx for both Slicer3
#   std::cout << std::endl << "AY-added in generic2000...txx: m_FinalMetricValue = " << m_FinalMetricValue << std::endl << std::endl;
# For reflecting the edit, you have to update genericRegistrationHelper.h since the source file is not cxx but txx.
# 2. itkRegularStepGradientDescentBaseOptimizer.cxx
# change a line as follows at l.246 for only the latter Slicer3
#   if( m_CurrentStepLength < m_MinimumStepLength )
#   -> if( 1 )


#--------------------------------------------------------------------
# Update History
# 8/22/2012: coding, basic test 
# 9/ 1/2012: coding, basic test
# 9/ 2/2012: combine all three steps
# 10/5/2012: coding to use TRE, 95%HD, and DSC for  assessment of accurucy for nonrigid registration
# 10/10/2012: coding, basic test
#--------------------------------------------------------------------

#--------------------------------------------------------------------
# set three parameters
#--------------------------------------------------------------------
# 1. sample number
#sample=(5000 6000 7000 8000 9000 10000 20000 30000 40000 50000 60000 70000 80000 90000 100000 )
sample=(4000 6000 8000 10000 20000 40000 60000 80000 100000 120000 140000 160000 180000 200000)
#sample=(180000)

# 2. number of histogram bins
# written in the loop of each step

# 3. grid number
# written in the loop of each step
#--------------------------------------------------------------------

echo "----------------------------------------------------------------------------"
echo "STEP 0.0: SET UP VARIABLES"
echo "----------------------------------------------------------------------------"

preFcsv="L-pre.fcsv"
postFcsv="L-post.fcsv"

inputpath=/media/TOSHIBAEXT/IBM4/Materials/
outputPath=/media/TOSHIBAEXT/IBM4/CalculationResults/
slicer_path=/home/CTGuidedAblation/Applicaiton/Slicer-release/Slicer3-build/lib/Slicer3/Plugins
pathForFcsvFile=/home/CTGuidedAblation/LIVER_CASES/CostfunctionCalculation/BrainsFit-CLI-testIBM4/
        
fixedVolume=$inputpath"N4-post-new.nrrd"
movingVolume=$inputpath"N4-pre-new.nrrd"
fixedBinaryVolume=$inputpath"post-MRI-label2.nrrd"
movingBinaryVolume=$inputpath"N4-pre-label.nrrd"
fiducialFile=$pathForFcsvFile$preFcsv

savefilename=TargetRegistrationErrors.csv


      resultHead=`echo "numberOfHistogramBins,plineGridSize,numberOfSamples,positionPre_x[0],positionPre_y[0],positionPre_z[0],positionPre_x[1],positionPre_y[1],positionPre_z[1],positionPre_x[2],positionPre_y[2],positionPre_z[2],positionPre_x[3],positionPre_y[3],positionPre_z[3],positionPreDeformed_x[0],positionPreDeformed_y[0],positionPreDeformed_z[0],positionPreDeformed_x[1],positionPreDeformed_y[1],positionPreDeformed_z[1],positionPreDeformed_x[2],positionPreDeformed_y[2],positionPreDeformed_z[2],positionPreDeformed_x[3],positionPreDeformed_y[3],positionPreDeformed_z[3],error_x[0],error_y[0],error_z[0],error_x[1],error_y[1],error_z[1],error_x[2],error_y[2],error_z[2],error_x[3],error_y[3],error_z[3],error[0],error[1],error[2],error[3],error"`
      echo "$resultHead" >>$savefilename


declare -i n=1
declare -i i=0

declare -a positionPre_x=(0 0 0 0)
declare -a positionPre_y=(0 0 0 0)
declare -a positionPre_z=(0 0 0 0)

declare -a positionPost_x=(0 0 0 0)
declare -a positionPost_y=(0 0 0 0)
declare -a positionPost_z=(0 0 0 0)

declare -a positionPreDeformed_x=(0 0 0 0)
declare -a positionPreDeformed_y=(0 0 0 0)
declare -a positionPreDeformed_z=(0 0 0 0)

declare -a error_x=(0 0 0 0)
declare -a error_y=(0 0 0 0)
declare -a error_z=(0 0 0 0)
declare -a error=(0 0 0 0 0)
averageError=0.0


echo "----------------------------------------------------------------------------"
echo "STEP 0.5: READ .fcsv FILES"
echo "----------------------------------------------------------------------------"
 
# read target position for moving images
echo $preFcsv
while read LINE; do

  if [ $n -ge 19 ]; then
    # get each field
    position_name=`echo ${LINE} | cut -d , -f 1`
    positionPre_x[i]=`echo ${LINE} | cut -d , -f 2`
    positionPre_y[i]=`echo ${LINE} | cut -d , -f 3`
    positionPre_z[i]=`echo ${LINE} | cut -d , -f 4`

    echo "positionPre[$i]: x=${positionPre_x[i]}, y=${positionPre_y[i]}, z=${positionPre_z[i]}"
    i=i+1
  fi
  n=n+1
  
done < $preFcsv

n=1
i=0
# read target position for fixed images
echo $postFcsv
while read LINE; do

  if [ $n -ge 19 ]; then
    # get each field
    position_name=`echo ${LINE} | cut -d , -f 1`
    positionPost_x[i]=`echo ${LINE} | cut -d , -f 2`
    positionPost_y[i]=`echo ${LINE} | cut -d , -f 3`
    positionPost_z[i]=`echo ${LINE} | cut -d , -f 4`

    echo "positionPost[$i]: x=${positionPost_x[i]}, y=${positionPost_y[i]}, z=${positionPost_z[i]}"
    i=i+1
  fi
  n=n+1
  
done < $postFcsv


# ----------------------------------------------------------------------------
# STEP 1-4: PERFORM INTENSITY-BASED NONRIGID REGISTRATION
# ----------------------------------------------------------------------------

echo "----------------------------------------------------------------------------"
echo "STEP 1: CREATE VOLUME BY INTENSITY-BASED NONRIGID REGISTRATION"
echo "STEP 2: TRANSFORM FIDUCIAL LIST TO EVALUATE REGISTRATION"
echo "STEP 3: CALCULATE TARGET REGISTRATION ERRORS"
echo "STEP 4: WRITE CALCULATED DATA TO CSV FILE"
echo "----------------------------------------------------------------------------"

      # Write initial record TRE csv file
      #result=`'numberOfHistogramBins','splineGridSize','numberOfSamples','positionPre_x[0]','positionPre_y[0]','positionPre_z[0]','positionPre_x[1]','positionPre_y[1]','positionPre_z[1]','positionPre_x[2]','positionPre_y[2]','positionPre_z[2]','positionPre_x[3]','positionPre_y[3]','positionPre_z[3]','positionPre_z[3]','positionPreDeformed_x[0]','positionPreDeformed_y[0]','positionPreDeformed_z[0]','positionPreDeformed_x[1]','positionPreDeformed_y[1]','positionPreDeformed_z[1]','positionPreDeformed_x[2]','positionPreDeformed_y[2]','positionPreDeformed_z[2]','positionPreDeformed_x[3]','positionPreDeformed_y[3]','positionPreDeformed_z[3]','error_x[0]','error_y[0]','error_z[0]','error_x[1]','error_y[1]','error_z[1]','error_x[2]','error_y[2]','error_z[2]','error_x[3]','error_y[3]','error_z[3]','error[0]','error[1]','error[2]','error[3]','error'`
      #echo $result >> $savefilename


for numberOfHistogramBins in {40..60}
do
    for splineGridSize in 3 4 5 6
    do
	for numberOfSamples in ${sample[@]}
	do
	    outputVolume=$inputpath"image-$numberOfHistogramBins-$splineGridSize-$numberOfSamples.nrrd"
      deformedGridImage=$outputPath"gridImages/""gridImage-$numberOfHistogramBins-$splineGridSize-$numberOfSamples.nrrd"
      bsplineTransform=$outputPath"transform/""transform-$numberOfHistogramBins-$splineGridSize-$numberOfSamples.mat"
      outtext=$outputPath"txt/""image-$numberOfHistogramBins-$splineGridSize-$numberOfSamples.txt"
      anatomicalFcsv="anatomicalMarkers-$numberOfHistogramBins-$splineGridSize-$numberOfSamples.fcsv"
	    outputFcsv=$outputPath"txt/"$anatomicalFcsv
      
      echo ""  
      echo "STEP1: Creating image-$numberOfHistogramBins-$splineGridSize-$numberOfSamples.nrrd..."
  		$slicer_path/BRAINSFitIGT --fixedVolume $fixedVolume --movingVolume $movingVolume --useCenterOfROIAlign --useRigid --useScaleVersor3D --useScaleSkewVersor3D --useAffine --useROIBSpline --bsplineTransform $bsplineTransform --outputVolume $outputVolume --outputVolumePixelType float --numberOfIterations 1500 --numberOfSamples $numberOfSamples --minimumStepSize 0.005 --translationScale 1000 --reproportionScale 1 --skewScale 1 --splineGridSize $splineGridSize,$splineGridSize,$splineGridSize --maxBSplineDisplacement 0 --backgroundFillValue 0 --maskInferiorCutOffFromCenter 1000 --interpolationMode BSpline --maskProcessingMode ROI --fixedBinaryVolume $fixedBinaryVolume --movingBinaryVolume $movingBinaryVolume --fixedVolumeTimeIndex 0 --movingVolumeTimeIndex 0 --medianFilterSize 0,0,0 --numberOfHistogramBins $numberOfHistogramBins --numberOfMatchPoints 10 --useCachingOfBSplineWeightsMode ON --useExplicitPDFDerivativesMode AUTO --ROIAutoDilateSize 0 --relaxationFactor 0.5 --maximumStepSize 0.2 --failureExitCode -1 --debugNumberOfThreads -1 --debugLevel 0 --costFunctionConvergenceFactor 1e+09 --projectedGradientTolerance 1e-05 --deformedGridImage $deformedGridImage >& $outtext
      # echo "$slicer_path/BRAINSFitIGT --fixedVolume $fixedVolume --movingVolume $movingVolume --useCenterOfROIAlign --useRigid --useScaleVersor3D --useScaleSkewVersor3D --useAffine --useROIBSpline --bsplineTransform $bsplineTransform --outputVolume $outputVolume --outputVolumePixelType float --numberOfIterations 1500 --numberOfSamples $numberOfSamples --minimumStepSize 0.005 --translationScale 1000 --reproportionScale 1 --skewScale 1 --splineGridSize $splineGridSize,$splineGridSize,$splineGridSize --maxBSplineDisplacement 0 --backgroundFillValue 0 --maskInferiorCutOffFromCenter 1000 --interpolationMode BSpline --maskProcessingMode ROI --fixedBinaryVolume $fixedBinaryVolume --movingBinaryVolume $movingBinaryVolume --fixedVolumeTimeIndex 0 --movingVolumeTimeIndex 0 --medianFilterSize 0,0,0 --numberOfHistogramBins $numberOfHistogramBins --numberOfMatchPoints 10 --useCachingOfBSplineWeightsMode ON --useExplicitPDFDerivativesMode AUTO --ROIAutoDilateSize 0 --relaxationFactor 0.5 --maximumStepSize 0.2 --failureExitCode -1 --debugNumberOfThreads -1 --debugLevel 0 --costFunctionConvergenceFactor 1e+09 --projectedGradientTolerance 1e-05 --deformedGridImage $deformedGridImage >& $outtext "


	    echo ""
	    echo "STEP2: Transforming Fiducial List in image-$numberOfHistogramBins-$splineGridSize-$numberOfSamples.txt..."
	    $slicer_path/TransformFiducialList --inputfiducials ${positionPre_x[0]},${positionPre_y[0]},${positionPre_z[0]} --inputfiducials ${positionPre_x[1]},${positionPre_y[1]},${positionPre_z[1]} --inputfiducials ${positionPre_x[2]},${positionPre_y[2]},${positionPre_z[2]} --inputfiducials ${positionPre_x[3]},${positionPre_y[3]},${positionPre_z[3]} --inputtransform $bsplineTransform --movingimage $movingVolume --referenceimage $fixedVolume --outputfiducialsfile $outputFcsv 

	    echo ""
	    echo "STEP3: Calculating Fiducial Registration Errors..."

      n=1
      i=0
      # read target position for fixed images
      echo $outputFcsv
      while read LINE; do

        #if [ $n -ge 19 ]; then
          # get each field
          position_name=`echo ${LINE} | cut -d , -f 1`
          positionPreDeformed_x[i]=`echo ${LINE} | cut -d , -f 2`
          positionPreDeformed_y[i]=`echo ${LINE} | cut -d , -f 3`
          positionPreDeformed_z[i]=`echo ${LINE} | cut -d , -f 4`
          #execute command
          echo "positionPreDeformed[$i], x=${positionPreDeformed_x[i]}, y=${positionPreDeformed_y[i]}, z=${positionPreDeformed_z[i]}"
          i=i+1
        #fi
        n=n+1
  
      done < $outputFcsv

      echo ""
      echo "STEP4: Calculating erroes..."
      i=0
      for ((i=0; i<4; i++))# in 0 1 2 3
      do
	#positionPreDeformed_x[i]= $(( scale=10; positionPreDeformed_x[i])) ` | bc
        error_x[$i]=`echo "scale=10; ${positionPreDeformed_x[$i]} - ${positionPost_x[$i]} " | bc `
	error_y[$i]=`echo "scale=10; ${positionPreDeformed_y[$i]} - ${positionPost_y[$i]} " | bc `
	error_z[$i]=`echo "scale=10; ${positionPreDeformed_z[$i]} - ${positionPost_z[$i]} " | bc `

	error[$i]=`echo "scale=10; sqrt(${error_x[$i]} * ${error_x[$i]} + ${error_y[$i]} * ${error_y[$i]} + ${error_z[$i]} * ${error_z[$i]} )  " | bc `
        done
	averageError=`echo "scale=10; (${error[0]} * ${error[1]} + ${error[2]} + ${error[3]} )/4  " | bc `     
	#averageError=`echo "("$error[0]"+"$error[1]"+"$error[2]"+"$error[3]")/4.0"|bc`
      
      
	echo ""
	echo "STEP5: Saving Data to csv file..."

      # Write file

      result=`echo "$numberOfHistogramBins,$splineGridSize,$numberOfSamples,${positionPre_x[0]},${positionPre_y[0]},${positionPre_z[0]},${positionPre_x[1]},${positionPre_y[1]},${positionPre_z[1]},${positionPre_x[2]},${positionPre_y[2]},${positionPre_z[2]},${positionPre_x[3]},${positionPre_y[3]},${positionPre_z[3]},${positionPreDeformed_x[0]},${positionPreDeformed_y[0]},${positionPreDeformed_z[0]},${positionPreDeformed_x[1]},${positionPreDeformed_y[1]},${positionPreDeformed_z[1]},${positionPreDeformed_x[2]},${positionPreDeformed_y[2]},${positionPreDeformed_z[2]},${positionPreDeformed_x[3]},${positionPreDeformed_y[3]},${positionPreDeformed_z[3]},${error_x[0]},${error_y[0]},${error_z[0]},${error_x[1]},${error_y[1]},${error_z[1]},${error_x[2]},${error_y[2]},${error_z[2]},${error_x[3]},${error_y[3]},${error_z[3]},${error[0]},${error[1]},${error[2]},${error[3]},$averageError"`
      echo "Saving data of "$savefilename
      echo "$result" >>$savefilename
      echo "$resultHead"
      echo "$result"
      
    done
    done
done



