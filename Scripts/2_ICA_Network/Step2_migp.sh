#!/bin/bash

INPUT_LIST="/dat05/users/zhanghuihua/brain_development/less_out/ICA_out/input_files.txt"
OUTPUT_DIR="/dat05/users/zhanghuihua/brain_development/less_out/ICA_out/2_Melodic_Results.ica_15/"

melodic -i $INPUT_LIST \
        -o $OUTPUT_DIR \
        -a concat \
        --nomask \
        --bgthreshold=-1 \
        --sep_vn \
        -d 15 \
        --Oall \
        --report \
        -v#!/bin/bash

INPUT_LIST="/dat05/users/zhanghuihua/brain_development/less_out/ICA_out/input_files.txt"
OUTPUT_DIR="/dat05/users/zhanghuihua/brain_development/less_out/ICA_out/2_Melodic_Results.ica_15/"

melodic -i $INPUT_LIST \
        -o $OUTPUT_DIR \
        -a concat \
        --nomask \
        --bgthreshold=-1 \
        --sep_vn \
        -d 15 \
        --Oall \
        --report \
        -v
