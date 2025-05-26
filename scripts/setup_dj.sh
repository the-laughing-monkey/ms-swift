#!/bin/bash

# Setup script for installing python packages for ms-swift
# Assumes you are in the activated virtual environment.
# This script adapts instructions from sections 4, 5, and 6 of the deployment guide for ms-swift.

#############################
# Define Repository Root for ms-swift Fork
#############################

# Use an absolute path for robustness, assuming /workspace is the intended base.
SWIFT_REPO_ROOT="/workspace/ms-swift"
FORK_URL="https://github.com/the-laughing-monkey/ms-swift"

#############################
# Set Working Root
#############################

WORKING_DIR="$(pwd)" # Use current working directory

#############################
# Set maximum number of open file descriptors
#############################

echo "Setting maximum number of open file descriptors to unlimited"
ulimit -n 65536

#############################
# 1. Install Core Python Packages and PyTorch
#############################

# Define core required python packages
PACKAGES="pip wheel packaging setuptools huggingface_hub qwen-vl-utils sgl-kernel mathruler"

echo "Upgrading pip"
python3 -m pip install --upgrade pip

echo "Installing core python packages: $PACKAGES"
pip install $PACKAGES


echo "Installing a PyTorch version compatible with ms-swift, vLLM, and CUDA 12.4"
pip install --no-cache-dir torch==2.6.0 torchvision==0.21.0 torchaudio==2.6.0 --index-url https://download.pytorch.org/whl/cu124

echo "Core python package and PyTorch installation complete."

#############################
# 2. Clone ms-swift Fork and Install
#############################

# Change to the parent directory before removing the repository
echo "Changing directory to /workspace before removing and cloning the repository"
cd /workspace

# Remove existing ms-swift directory if it exists from previous runs
if [ -d "$SWIFT_REPO_ROOT" ]; then
    echo "Removing existing ms-swift repository: $SWIFT_REPO_ROOT"
    rm -rf "$SWIFT_REPO_ROOT"
fi

echo "Cloning ms-swift fork repository into $SWIFT_REPO_ROOT"
git clone "$FORK_URL" "$SWIFT_REPO_ROOT"

# Change back into the cloned ms-swift repository for installation
echo "Changing directory to ms-swift repository: $SWIFT_REPO_ROOT"
cd "$SWIFT_REPO_ROOT"

# Install ms-swift in editable mode with default extra (excluding vllm and sglang dependencies already installed)
echo "Installing ms-swift with default extra"
pip install -e .[default]


echo "Installing deepspeed"
pip install deepspeed

# Install vLLM and SGLang explicitly with specified versions (if needed by ms-swift or your workflow)
echo "Installing vLLM"
pip install vllm

echo "Installing sglang"
pip install sglang[all]

# Install flash_attn separately with no-build-isolation and specific version/index url
# This is kept separate as it's a common source of issues and explicitly controlling it can help
echo "Installing flash-attn with --no-build-isolation"
pip install --no-build-isolation flash-attn

echo "ms-swift and required dependencies installation complete."


# Verify installed versions
echo "Installed package versions:"
python -c "import torch; print(f'torch: {torch.__version__}')" || echo "torch: Not Found or Failed to Import"
python -c "import vllm; print(f'vllm: {vllm.__version__}')" || echo "vllm: Not Found or Failed to Import"
python -c "import flash_attn; print(f'flash-attn: {flash_attn.__version__}')" || echo "flash-attn: Not Found or Failed to Import"
python -c "import ray; print(f'ray: {ray.__version__}')" || echo "ray: Not Found or Failed to Import"
python -c "import swift; print('ms-swift: Installed')" || echo "ms-swift: Not Found or Failed to Import"