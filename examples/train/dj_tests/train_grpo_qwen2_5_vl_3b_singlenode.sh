#!/bin/bash
set -ex

# Please run this script from the root of the ms-swift repo

export CUDA_VISIBLE_DEVICES=0,1 # Use 2 GPUs
NPROC_PER_NODE=2

swift rlhf \
    --rlhf_type grpo \
    --model Qwen/Qwen2.5-VL-3B-Instruct \
    --train_type lora \
    --dataset AI-ModelScope/chartqa_digit_r1v_format \
    --use_vllm true \
    --vllm_mode colocate \
    --vllm_gpu_memory_utilization 0.5 \
    --vllm_tensor_parallel_size 2 \
    --torch_dtype bfloat16 \
    --system examples/train/grpo/prompt.txt \
    --num_train_epochs 1 \
    --per_device_train_batch_size 1 \
    --per_device_eval_batch_size 1 \
    --learning_rate 1e-6 \
    --save_total_limit 2 \
    --logging_steps 5 \
    --output_dir output \
    --gradient_accumulation_steps 1 \
    --warmup_ratio 0.05 \
    --dataloader_num_workers 4 \
    --max_completion_length 1024 \
    --reward_funcs accuracy format \
    --num_generations 8 \
    --sleep_level 1 \
    --temperature 1.0 \
    --top_p 0.85