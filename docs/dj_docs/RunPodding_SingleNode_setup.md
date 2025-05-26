# Running ms-swift on RunPod: The Ultimate Deployment Guide

Welcome to the ms-swift RunPodding guide!  
Here, we show you how to unleash ms-swift on a RunPod instance. Whether you're working on large language model post-training or multimodal reinforcement learning, this guide will get you set up with a system that boasts substantial storage and leverages best practices for distributed training.

---

## Prerequisites

- A RunPod account with sufficient credits
- Basic familiarity with Linux commands and SSH
- An SSH client on your local machine  
- Patience—and maybe a snack!
- When using Ray for distributed training, **ensure that port 6379 is open** on the Ray head node for worker join and **port 8265 is open** for job submission and dashboard access. These ports are used for:
  - **Worker Join:** The head node listens on `http://<HEAD_NODE_IP>:6379` for worker nodes connecting to the cluster.
  - **Job Submission & Dashboard:** The head node listens on `http://<HEAD_NODE_IP>:8265` for job submissions and dashboard communications.
- **Before running any training or job submission scripts, be sure to start Ray on your pod.**  
  Please refer to the [Ray documentation](https://docs.ray.io/).

---

## Step-by-Step Instructions

### 1. Create Your Storage Volume

1. Log in to your RunPod account.
2. Navigate to the **Volumes** section and click **Create Volume**.
3. Name your volume (we recommend `data`) and set the size (2000GB).
4. Select your preferred datacenter and click **Create**.

### 2. Launch Your Pod

1. In the **Pods** section, click **+ Deploy**.

Choose the number of nodes you want to deploy.
 

2. Set your GPU count (more than one if you like parallel power!).

3. Choose the correct template:
RunPod Pytorch 2.4.0  (by default it pickes 2.2.1) OR 2.8 for Blackwell cards.

4. Click **Edit Template** to adjust:
   - Container disk size (100GB is a good start).
   - Attach your volume by mounting it to `/data`.
   - Enable a public IP.

5. Ensure that "ssh" is checked, then click **Deploy**.

### 3. Configure Your SSH Access

1. Generate your SSH key locally:
```bash
   ssh-keygen -t my_runpod_key -C "your_email@example.com"
   cat ~/.ssh/my_runpod_key.pub
```
2. Log into your RunPod account and paste your public key under **SSH Public Keys**.

3. Once your pod is live, note its IP and SSH port. Then connect using:
```bash
   ssh -i ~/.ssh/my_runpod_key root@<POD_IP_ADDRESS> -p <SSH_PORT>
```

### 4. Set Up Your Python Environment and Install Dependencies using the Setup Script

1. Update the system and install necessary tools:
```bash
   apt update && apt upgrade -y && apt install -y python3-pip python3-venv python3-dev build-essential git curl vim lsof net-tools rsync libopenmpi-dev build-essential dkms dnsutils dnsutils iputils-ping
```


2. Create a virtual environment in your data directory:


```bash
   mkdir /workspace
   cd /workspace
   python3 -m venv swift-env
   source swift-env/bin/activate
```

3. Clone the ms-swift fork repository:
```bash
   cd /workspace
   git clone https://github.com/the-laughing-monkey/ms-swift.git
```

4. Navigate to the scripts directory within the cloned repository and run the setup script (`setup_dj.sh`) to install ms-swift and other dependencies:
```bash
   cd /workspace/ms-swift/
   bash ./scripts/setup_dj.sh
```
---

### 5. (Optional) Set Your WandB API Key

If you wish to use Weights & Biases (wandb) for experiment tracking, set your API key:

```bash
    export WANDB_API_KEY=YOUR_WANDB_API_KEY
```
This step is optional but recommended for more integrated experiment monitoring.


### 6. Prepare Your Cache

Move model caches to your larger `/data` volume to conserve space:
```bash
    mkdir -p /data/cache-models/huggingface/hub /data/cache-models/modelscope/hub /data/cache-ray
    rm -rf /root/.cache/huggingface && ln -s /data/cache-models/huggingface /root/.cache/huggingface
    rm -rf /root/.cache/modelscope && ln -s /data/cache-models/modelscope /root/.cache/modelscope
    # DO NOT DO THE RAY PART ON A NETWORK DISK. Insread make your local /root disk LARGE. Like 2GB.
    rm -rf /root/.cache/ray && ln -s /data/cache-ray /root/.cache/ray
    # Verify symlinks
    ls -la /root/.cache/
```

This is a critical step because:
- Model training checkpoints can be large (multiple GB each)
- The default container disk (50GB) will quickly fill up during training
- Moving these to your data volume (500GB-1000GB) prevents "No space left on device" errors

---

### 7. Download Your Model and Dataset for ms-swift

ms-swift supports various datasets and has its own format and preparation methods. Refer to the [ms-swift documentation on Supported Models and Datasets](https://swift.readthedocs.io/en/latest/Instruction/Supported-Models-and-Datasets.html) and [Custom Dataset](https://swift.readthedocs.io/en/latest/Customization/Custom-Dataset.html) for detailed instructions on preparing your specific dataset.

1. Navigate to the ms-swift repository directory:
```bash
    cd /workspace/ms-swift
```

2. Download the Qwen2.5-VL-3B model using the provided downloader script:
```bash
    python3 examples/downloaders/download_model.py --model_name Qwen/Qwen2.5-VL-3B-Instruct --root_dir /data/cache-models/huggingface/hub
```

3. Create the datasets directory:
```bash
    mkdir -p /data/datasets
```

4. Download the `lmms-lab/multimodal-open-r1-8k-verified` dataset using the generic downloader script:

```bash
    python3 examples/downloaders/download_dataset.py --dataset_name lmms-lab/multimodal-open-r1-8k-verified --root_dir /data/datasets/lmms-lab/multimodal-open-r1-8k-verified
```

---

### 8. Set your NCCL environment variables to use the eth1 interface:

CRITICAL: RunPod only allows internode communication over eth1. So you need to set your NCCL to use the eth1 IP or NCCL will fail to update weights across nodes.

```bash
    export NCCL_DEBUG=INFO
```


### 9. Start Ray (if you are using Ray)

2. Stop any running Ray instances (if any):
```bash
    ray stop
```

3. Start the Ray head node bound to all available IPs:
```bash
    ray start --head --node-ip-address 0.0.0.0 --port=6379 --dashboard-port=8265   --temp-dir ~/.cache/ray
```


### 10. Run Your ms-swift Training Job

Now you're ready to launch a training job using ms-swift. You can use the modified script `dj_tests/train_grpo_qwen2_5_vl_3b_singlenode.sh` that was created earlier. Remember to replace the dummy dataset in the script with your actual dataset.

1. Copy the script to your pod:

```bash
   # Assuming the script is in your local machine's dj_tests directory
   # You may need to adjust the source path if the script is elsewhere
   scp -i ~/.ssh/my_runpod_key -P <SSH_PORT> ./dj_tests/train_grpo_qwen2_5_vl_3b_singlenode.sh root@<POD_IP_ADDRESS>:/workspace/dj_tests/
```

2. Run the training script:
```bash
    cd /workspace/dj_tests
    bash ./train_grpo_qwen2_5_vl_3b_singlenode.sh
```

---

### 11. Monitoring NVIDIA GPU Memory

To monitor the NVIDIA GPU memory usage while the script loads and runs, open a new terminal session (or use a multiplexer like tmux/screen) and run:

```bash
watch -n 1 nvidia-smi
```

# or

```bash
watch -n 1 "nvidia-smi --query-gpu=timestamp,index,name,utilization.gpu,utilization.memory,temperature.gpu,fan.speed,memory.total,memory.used,memory.free --format=csv,noheader,nounits"
```

# or

```bash
watch -n 1 "echo 'GPU   Total(MiB)   Used(MiB)'; nvidia-smi --query-gpu=index,memory.total,memory.used --format=csv,noheader,nounits | awk -F',' '{printf \"%-3s %-12s %-10s\n\", \$1, \$2, \$3}'"
```

### 12. Monitoring and Managing Disk Space

Running out of disk space is a common issue during training. To monitor disk usage:

```bash
# Check overall disk usage
df -h

# Find largest directories and files in /root
du -h --max-depth=2 /root | sort -hr | head -20

# Find largest directories in Ray cache
du -h --max-depth=2 /data/cache-ray | sort -hr | head -20

# Find large checkpoint files
find /data -name "*.pt" -size +1G | xargs ls -lh
```

If you're running low on disk space despite using the data volume:

```bash
# Clear Triton cache (safe to delete)
rm -rf /root/.triton/autotune

# Clear older Ray session directories (if not using the symlink setup)
find /root/.cache/ray/session_* -maxdepth 0 -type d | sort | head -n -2 | xargs rm -rf

# Reduce checkpoint frequency in training scripts
# Example: Change --save_steps 10 to --save_steps 50

# Limit the number of checkpoints kept
# Example: Add --max_ckpt_num 2 to training arguments
```

For critical low disk situations, you can safely clear caches:

```bash
# Clear PyTorch hub cache
rm -rf /root/.cache/torch/hub/*

# Remove older checkpoints if needed
find /data/checkpoints -name "global_step*" | sort | head -n -2 | xargs rm -rf
```

### Troubleshooting

#### "Too many open files" error (Raylet or other Ray process)

This error occurs when a Ray process (like the raylet) exceeds the operating system's limit on the number of open file descriptors. Ray uses file descriptors for various resources, including network sockets for internal communication (gRPC). With a large number of tasks or actors, Ray can open many connections, hitting the default limit.

To resolve this, increase the file descriptor limit (`ulimit -n`) for the user running the Ray processes *before* starting Ray. A common value is 65536.

```bash
ulimit -n 65536
# Then run your ray start or training command
ray start --head ... # or ray start --address=...
```

You should apply this command in the terminal session *before* executing the Ray start command on both head and worker nodes.



