#!/bin/bash

HEMI_TO_RUN="L"
THRESHOLD=0.05
BASE_PATH="/dat05/users/zhanghuihua/brain_development/less_out/fused_out/out_4/"
OUTPUT_DIR="/dat05/users/zhanghuihua/brain_development/less_out/fused_out/out_4/MPM_0.05_results/"

mkdir -p "$OUTPUT_DIR"

if [ "$HEMI_TO_RUN" == "L" ]; then
    C1_IN="${BASE_PATH}IPL_connection_C1/average_L_projection_C1_native.func.gii"
    C2_IN="${BASE_PATH}IPL_connection_C2/average_L_projection_C2_native.func.gii"
    C3_IN="${BASE_PATH}IPL_connection_C3/average_L_projection_C3_native.func.gii"
    C4_IN="${BASE_PATH}IPL_connection_C4/average_L_projection_C4_native.func.gii"
    OUTPUT_MPM="${OUTPUT_DIR}IPL_MPM_L.func.gii"
elif [ "$HEMI_TO_RUN" == "R" ]; then
    C1_IN="${BASE_PATH}IPL_connection_C1/average_R_projection_C1_native.func.gii"
    C2_IN="${BASE_PATH}IPL_connection_C2/average_R_projection_C2_native.func.gii"
    C3_IN="${BASE_PATH}IPL_connection_C3/average_R_projection_C3_native.func.gii"
    C4_IN="${BASE_PATH}IPL_connection_C4/average_R_projection_C4_native.func.gii"
    OUTPUT_MPM="${OUTPUT_DIR}IPL_MPM_R.func.gii"
else
    exit 1
fi

wb_command -metric-math \
   "max( \
        (C1 > $THRESHOLD) * C1, \
        max( (C2 > $THRESHOLD) * C2, \
             max( (C3 > $THRESHOLD) * C3, (C4 > $THRESHOLD) * C4 ) \
           ) \
      )" \
   "$OUTPUT_MPM" \
   -var C1 "$C1_IN" \
   -var C2 "$C2_IN" \
   -var C3 "$C3_IN" \
   -var C4 "$C4_IN"#!/bin/bash

HEMI_TO_RUN="L"
THRESHOLD=0.05
BASE_PATH="/dat05/users/zhanghuihua/brain_development/less_out/fused_out/out_4/"
OUTPUT_DIR="/dat05/users/zhanghuihua/brain_development/less_out/fused_out/out_4/MPM_0.05_results/"

mkdir -p "$OUTPUT_DIR"

if [ "$HEMI_TO_RUN" == "L" ]; then
    C1_IN="${BASE_PATH}IPL_connection_C1/average_L_projection_C1_native.func.gii"
    C2_IN="${BASE_PATH}IPL_connection_C2/average_L_projection_C2_native.func.gii"
    C3_IN="${BASE_PATH}IPL_connection_C3/average_L_projection_C3_native.func.gii"
    C4_IN="${BASE_PATH}IPL_connection_C4/average_L_projection_C4_native.func.gii"
    OUTPUT_MPM="${OUTPUT_DIR}IPL_MPM_L.func.gii"
elif [ "$HEMI_TO_RUN" == "R" ]; then
    C1_IN="${BASE_PATH}IPL_connection_C1/average_R_projection_C1_native.func.gii"
    C2_IN="${BASE_PATH}IPL_connection_C2/average_R_projection_C2_native.func.gii"
    C3_IN="${BASE_PATH}IPL_connection_C3/average_R_projection_C3_native.func.gii"
    C4_IN="${BASE_PATH}IPL_connection_C4/average_R_projection_C4_native.func.gii"
    OUTPUT_MPM="${OUTPUT_DIR}IPL_MPM_R.func.gii"
else
    exit 1
fi

wb_command -metric-math \
   "max( \
        (C1 > $THRESHOLD) * C1, \
        max( (C2 > $THRESHOLD) * C2, \
             max( (C3 > $THRESHOLD) * C3, (C4 > $THRESHOLD) * C4 ) \
           ) \
      )" \
   "$OUTPUT_MPM" \
   -var C1 "$C1_IN" \
   -var C2 "$C2_IN" \
   -var C3 "$C3_IN" \
   -var C4 "$C4_IN"
