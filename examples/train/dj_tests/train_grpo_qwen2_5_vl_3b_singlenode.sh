#!/bin/bash
set -ex

# Please run this script from the root of the ms-swift repo

export CUDA_VISIBLE_DEVICES=0,1 # Use 2 GPUs
NPROC_PER_NODE=2

deepspeed --num_gpus ${NPROC_PER_NODE} /workspace/ms-swift/swift/cli/rlhf.py \
  --rlhf_type grpo \
  --model Qwen/Qwen2.5-VL-3B-Instruct \
  --train_type lora \
  --use_vllm true \
  --vllm_mode colocate \
  --vllm_gpu_memory_utilization 0.5 \
  --vllm_max_model_len 8192 \
  --vllm_tensor_parallel_size 2 \
  --dataset /data/datasets/lmms-lab/multimodal-open-r1-8k-verified \
  --external_plugins examples/train/grpo/plugin/plugin.py \
  --reward_funcs external_r1v_acc format \
  --reward_weights 1 0.1 \
  --torch_dtype bfloat16 \
  --attn_impl flash_attn \
  --num_train_epochs 1 \
  --max_length 8192 \
  --per_device_train_batch_size 1 \
  --per_device_eval_batch_size 1 \
  --gradient_accumulation_steps 1 \
  --eval_steps 500 \
  --save_steps 500 \
  --learning_rate 1e-6 \
  --save_total_limit 2 \
  --logging_steps 1 \
  --warmup_ratio 0.05 \
  --dataloader_num_workers 2 \
  --max_completion_length 2048 \
  --num_generations 8 \
  --deepspeed zero3 \
  --temperature 1.1 \
  --top_p 1.0 \
  --top_k 80 \
  --log_completions true \
  --async_generate false \
  --offload_optimizer true \
  --offload_model true \
  --gc_collect_after_offload true \
  --move_model_batches 40 \
  --sleep_level 1 \
  --report_to wandb \
  --system examples/train/grpo/prompt.txt