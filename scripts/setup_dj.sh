#!/bin/bash

# Setup script for installing python packages for ms-swift
# Assumes you are in the activated virtual environment.
# This script adapts instructions from sections 4, 5, and 6 of the deployment guide for ms-swift.


WORKING_DIR="$(pwd)" # Use current working directory
# No clone directory needed for ms-swift pip install

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
pip install --upgrade pip

echo "Installing core python packages: $PACKAGES"
pip install $PACKAGES


echo "Installing a PyTorch version compatible with ms-swift, vLLM, and CUDA 12.4"
pip install --no-cache-dir torch==2.6.0 torchvision==0.21.0 torchaudio==2.6.0 --index-url https://download.pytorch.org/whl/cu124

echo "Core python package and PyTorch installation complete."

#############################
# 2. Install ms-swift and Core Requirements
#############################

# Install ms-swift
echo "Installing ms-swift"
pip install ms-swift -U

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