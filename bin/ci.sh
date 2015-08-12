#!/bin/bash
FULL_VERSION=$(git --git-dir='.git' --work-tree='/' describe | sed -e 's/^v//' -e 's/g//')
tar -C 'built-framework' -c -f built-framework/SharethroughSDK.framework.${FULL_VERSION}.tar SharethroughSDK.framework
cd built-framework/ && zip -r SharethroughSDK.framework.${FULL_VERSION}.zip SharethroughSDK.framework/ && cd ..
tar -C 'built-framework' -c -f built-framework/SharethroughSDK+DFP.framework.${FULL_VERSION}.tar SharethroughSDK+DFP.framework
